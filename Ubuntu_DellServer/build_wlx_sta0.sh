#!/usr/bin/env bash
set -euo pipefail

AP_IF="${AP_IF:-wlx00c0cabb0b53}"
STA_IF="${STA_IF:-wlx_sta0}"
STA_MAC="${STA_MAC:-02:c0:ca:bb:0b:53}"
WPA_CONF="${WPA_CONF:-/home/gray.lin/OSPath/Ubuntu_DellServer/wlx_sta0_wpa.conf}"

need_cmd() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo "Missing required command: $1" >&2
        exit 1
    fi
}

run_root() {
    if [[ ${EUID} -eq 0 ]]; then
        "$@"
    else
        sudo "$@"
    fi
}

need_cmd iw
need_cmd ip
need_cmd wpa_supplicant
need_cmd wpa_cli
need_cmd dhclient

if [[ ! -r "${WPA_CONF}" ]]; then
    echo "Cannot read WPA config: ${WPA_CONF}" >&2
    exit 1
fi

echo "Rebuilding ${STA_IF} from ${AP_IF}"

if iw dev "${STA_IF}" info >/dev/null 2>&1; then
    echo "Stopping existing ${STA_IF} session"
    run_root wpa_cli -i "${STA_IF}" terminate >/dev/null 2>&1 || true
    run_root dhclient -r "${STA_IF}" >/dev/null 2>&1 || true
    run_root ip link set "${STA_IF}" down >/dev/null 2>&1 || true
    run_root iw dev "${STA_IF}" del
fi

echo "Creating ${STA_IF}"
run_root iw dev "${AP_IF}" interface add "${STA_IF}" type managed
run_root ip link set "${STA_IF}" down
run_root ip link set "${STA_IF}" address "${STA_MAC}"
run_root ip link set "${STA_IF}" up

echo "Starting wpa_supplicant"
run_root wpa_supplicant -B -i "${STA_IF}" -c "${WPA_CONF}"

echo "Waiting for Wi-Fi association"
for _ in {1..20}; do
    if run_root wpa_cli -i "${STA_IF}" status 2>/dev/null | grep -q '^wpa_state=COMPLETED$'; then
        break
    fi
    sleep 1
done

if ! run_root wpa_cli -i "${STA_IF}" status 2>/dev/null | grep -q '^wpa_state=COMPLETED$'; then
    echo "${STA_IF} did not associate. Current status:" >&2
    run_root wpa_cli -i "${STA_IF}" status >&2 || true
    exit 1
fi

echo "Requesting DHCP lease"
run_root dhclient -r "${STA_IF}" >/dev/null 2>&1 || true
run_root dhclient -v "${STA_IF}"

echo
echo "Connection status:"
run_root wpa_cli -i "${STA_IF}" status | grep -E '^(ssid|bssid|freq|wpa_state|ip_address|address)=' || true
ip addr show dev "${STA_IF}" || run_root ip addr show dev "${STA_IF}"
