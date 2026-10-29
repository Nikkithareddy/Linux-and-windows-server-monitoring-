#!/usr/bin/env bash
# collect_logs.sh - bundle the logs needed for troubleshooting into one archive.
# Usage: sudo ./collect_logs.sh [output_dir]
set -eu

OUT_DIR=${1:-/tmp}
STAMP=$(date +%Y%m%d_%H%M%S)
WORK="$OUT_DIR/logs_$(hostname)_$STAMP"
mkdir -p "$WORK"

# Copy whichever of the common log files exist on this distro
for f in /var/log/messages /var/log/syslog /var/log/secure /var/log/auth.log \
         /var/log/lab-monitor/monitor.log; do
    [ -f "$f" ] && cp "$f" "$WORK/" 2>/dev/null || true
done

journalctl -p warning --since "24 hours ago" --no-pager > "$WORK/journal_warnings_24h.txt" 2>/dev/null || true
systemctl --failed --no-pager > "$WORK/failed_units.txt" 2>/dev/null || true
df -h > "$WORK/disk_usage.txt"
free -m > "$WORK/memory.txt"
ps aux --sort=-%cpu | head -20 > "$WORK/top_cpu_processes.txt"

tar -czf "$WORK.tar.gz" -C "$OUT_DIR" "$(basename "$WORK")"
rm -rf "$WORK"
echo "Created $WORK.tar.gz"
