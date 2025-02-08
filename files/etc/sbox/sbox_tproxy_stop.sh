#!/bin/sh

timestamp() {
    date +"%Y-%m-%d %H:%M:%S"
}

error_exit() {
    echo "$(timestamp) Error: $1" >&2
    exit "${2:-1}"
}

trap 'error_exit "Script Interrupt"' INT TERM

rm -f /etc/nftables.d/99-singbox.nft && echo "$(timestamp) Delete rule"

nft delete table inet sing-box 2>/dev/null && echo "$(timestamp) delete sing-box table"

ip rule del fwmark 1 table 100 2>/dev/null && echo "$(timestamp) delete rule"
ip route flush table 100 && echo "$(timestamp) delete rule"

rm -f /tmp/sing-box/cache.db && echo "$(timestamp) clean cache"

echo "$(timestamp) Uninstall for sing-box"

