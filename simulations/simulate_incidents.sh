#!/usr/bin/env bash
# simulate_incidents.sh - safely trigger the three lab incidents on a LAB VM ONLY.
# Usage: sudo ./simulate_incidents.sh {cpu|disk|service} [service_name]
# Never run this on a real server.
set -eu

case "${1:-}" in
    cpu)
        # Load every core for 120 seconds, then stop automatically
        cores=$(nproc)
        echo "Loading $cores cores for 120s..."
        for ((i = 0; i < cores; i++)); do timeout 120 sh -c 'while :; do :; done' & done
        wait ;;
    disk)
        # Fill the filesystem holding /var/tmp up to ~95% with one removable file
        avail_kb=$(df -P /var/tmp | awk 'NR==2 {print $4}')
        total_kb=$(df -P /var/tmp | awk 'NR==2 {print $2}')
        fill_kb=$(( avail_kb - total_kb * 5 / 100 ))
        (( fill_kb > 0 )) || { echo "Already above 95% used."; exit 0; }
        echo "Writing ${fill_kb}KB to /var/tmp/lab_fill.img"
        fallocate -l "${fill_kb}K" /var/tmp/lab_fill.img
        echo "Clean up with: sudo rm /var/tmp/lab_fill.img" ;;
    service)
        svc=${2:-crond}
        echo "Stopping $svc"
        systemctl stop "$svc"
        echo "Recover with: sudo systemctl start $svc (or let service_restart.sh do it)" ;;
    *) echo "Usage: $0 {cpu|disk|service [name]}"; exit 1 ;;
esac
