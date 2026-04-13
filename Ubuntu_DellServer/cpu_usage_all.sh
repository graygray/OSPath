#!/bin/sh

set -eu

DURATION="${1:-5}"

case "$DURATION" in
    ''|*[!0-9.]*)
        echo "Usage: $0 [seconds]" >&2
        exit 1
        ;;
esac

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

read_user_process_jiffies() {
    awk '
    function trim_name(name) {
        sub(/^[[:space:]]+/, "", name)
        sub(/[[:space:]]+$/, "", name)
        return name
    }

    {
        pid = FILENAME
        sub(".*/", "", pid)

        line = $0
        name = line
        sub(/^[^(]*\(/, "", name)
        sub(/\).*/, "", name)
        name = trim_name(name)

        # Kernel threads are typically shown as [kthreadd], [rcu_*], etc.
        if (name ~ /^\[.*\]$/) {
            next
        }

        rest = line
        sub(/^[^(]*\([^)]*\)[[:space:]]*/, "", rest)
        n = split(rest, f, /[[:space:]]+/)

        # After removing "pid (comm)", utime and stime are fields 12 and 13.
        if (n >= 13) {
            sum += f[12] + f[13]
        }
    }

    END {
        print sum + 0
    }' /proc/[0-9]*/stat
}

start_total="$(read_total_jiffies)"
start_user="$(read_user_process_jiffies)"

echo "Measuring total CPU usage from all user-space processes over ${DURATION} seconds..."
sleep "$DURATION"

end_total="$(read_total_jiffies)"
end_user="$(read_user_process_jiffies)"

total_delta=$((end_total - start_total))
user_delta=$((end_user - start_user))

if [ "$total_delta" -le 0 ]; then
    echo "Unable to compute CPU usage: total CPU tick delta is zero." >&2
    exit 1
fi

usage_pct="$(awk -v user="$user_delta" -v total="$total_delta" 'BEGIN {
    printf "%.2f", (user / total) * 100
}')"

echo "Total CPU usage from all user-space processes: ${usage_pct}%"
