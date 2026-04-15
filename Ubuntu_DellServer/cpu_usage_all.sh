#!/bin/sh

set -eu

DURATION="${1:-5}"
TOP_N="${TOP_N:-10}"
TMPDIR="${TMPDIR:-/tmp}"
SELF_PID="$$"

case "$DURATION" in
    ''|*[!0-9.]*)
        echo "Usage: $0 [seconds]" >&2
        exit 1
        ;;
esac

case "$TOP_N" in
    ''|*[!0-9]*)
        echo "TOP_N must be an integer." >&2
        exit 1
        ;;
esac

read_total_user_jiffies() {
    awk '/^cpu / {
        print ($2 + $3)
        exit
    }' /proc/stat
}

read_total_jiffies() {
    awk '/^cpu / {
        total = 0
        for (i = 2; i <= NF; i++) {
            total += $i
        }
        print total
        exit
    }' /proc/stat
}

read_cpu_count() {
    cpu_count="$(getconf _NPROCESSORS_ONLN 2>/dev/null || true)"

    case "$cpu_count" in
        ''|*[!0-9]*)
            cpu_count="$(awk '/^cpu[0-9]+ / { count++ } END { print count + 0 }' /proc/stat)"
            ;;
    esac

    if [ "$cpu_count" -le 0 ]; then
        echo "Unable to determine online CPU count." >&2
        exit 1
    fi

    printf '%s\n' "$cpu_count"
}

take_snapshot() {
    out_file="$1"

    : > "$out_file"
    : > "${out_file}.cmd"

    for stat_file in /proc/[0-9]*/stat; do
        [ -r "$stat_file" ] || continue

        pid="${stat_file#/proc/}"
        pid="${pid%/stat}"

        cmdline_file="/proc/$pid/cmdline"

        awk -v pid="$pid" '
        function trim(s) {
            sub(/^[[:space:]]+/, "", s)
            sub(/[[:space:]]+$/, "", s)
            return s
        }

        {
            line = $0

            comm = line
            sub(/^[^(]*\(/, "", comm)
            sub(/\).*/, "", comm)
            comm = trim(comm)

            rest = line
            sub(/^[^(]*\([^)]*\)[[:space:]]*/, "", rest)
            n = split(rest, f, /[[:space:]]+/)

            # After stripping "pid (comm)", utime is field 12.
            if (n >= 12) {
                printf "%s\t%s\t%s\n", pid, f[12], comm
            }
        }' "$stat_file" >> "$out_file"

        if [ -r "$cmdline_file" ]; then
            cmdline="$(tr '\000' ' ' < "$cmdline_file" | sed 's/[[:space:]]*$//')"
            if [ -n "$cmdline" ]; then
                printf '%s\t%s\n' "$pid" "$cmdline" >> "${out_file}.cmd"
            fi
        fi
    done

    : > "${out_file}.merged"
    awk -F '\t' '
    NR == FNR {
        cmd[$1] = $2
        next
    }
    {
        pid = $1
        utime = $2
        comm = $3
        if (pid in cmd && cmd[pid] != "") {
            print pid "\t" utime "\t" cmd[pid]
        } else {
            print pid "\t" utime "\t[" comm "]"
        }
    }' "${out_file}.cmd" "$out_file" > "${out_file}.merged"

    mv "${out_file}.merged" "$out_file"
    rm -f "${out_file}.cmd"
}

snapshot1="$(mktemp "$TMPDIR/cpu_usage_all.XXXXXX")"
snapshot2="$(mktemp "$TMPDIR/cpu_usage_all.XXXXXX")"

cleanup() {
    rm -f "$snapshot1" "$snapshot2"
}
trap cleanup EXIT INT TERM

start_user="$(read_total_user_jiffies)"
start_total="$(read_total_jiffies)"
cpu_count="$(read_cpu_count)"
take_snapshot "$snapshot1"

echo "Measuring total CPU usage from all user-space processes over ${DURATION} seconds..."
echo ""
sleep "$DURATION"

end_user="$(read_total_user_jiffies)"
end_total="$(read_total_jiffies)"
take_snapshot "$snapshot2"

user_delta=$((end_user - start_user))
total_delta=$((end_total - start_total))

if [ "$total_delta" -le 0 ]; then
    echo "Unable to compute CPU usage: total CPU tick delta is zero." >&2
    exit 1
fi

total_user_pct="$(awk -v user="$user_delta" -v total="$total_delta" 'BEGIN {
    printf "%.2f", (user / total) * 100
}')"

cores_busy="$(awk -v user="$user_delta" -v total="$total_delta" -v cpus="$cpu_count" 'BEGIN {
    printf "%.2f", (user / total) * cpus
}')"

echo "Total user-space CPU usage: ${total_user_pct}% of machine capacity"
echo "Equivalent busy cores: ${cores_busy}"
echo ""
echo "Top ${TOP_N} processes by user-space CPU usage:"

top_output="$(awk -F '\t' -v total="$total_delta" -v self_pid="$SELF_PID" '
NR == FNR {
    prev[$1] = $2
    next
}
{
    pid = $1
    utime = $2
    cmd = $3

    if (pid == self_pid || cmd ~ /cpu_usage_all\.sh/) {
        next
    }

    if (!(pid in prev)) {
        next
    }

    delta = utime - prev[pid]
    if (delta < 0) {
        next
    }

    pct = (delta / total) * 100
    printf "%.2f\t%s\t%s\n", pct, pid, cmd
}' "$snapshot1" "$snapshot2" | sort -rn | head -n "$TOP_N" | awk -F '\t' '
{
    printf "CPU: %.2f%%\t| PID: %s\t| CMD: %s\n", $1, $2, $3
}
')"

if [ -n "$top_output" ]; then
    printf '%s\n' "$top_output"
else
    echo "No user-space process accumulated measurable CPU time during the sample window."
fi
