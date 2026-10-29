#!/usr/bin/env bash
# monitor.sh - health check for CPU, memory, disk and service status.
# Writes every run to a log file and raises an ALERT line (also sent to syslog)
# when a threshold is crossed. Intended to run from cron every minute.
set -u

CPU_THRESHOLD=${CPU_THRESHOLD:-85}
MEM_THRESHOLD=${MEM_THRESHOLD:-85}
DISK_THRESHOLD=${DISK_THRESHOLD:-90}
SERVICES=${SERVICES:-"sshd crond"}   # use "ssh cron" on Ubuntu
LOG_DIR=${LOG_DIR:-/var/log/lab-monitor}
LOG_FILE="$LOG_DIR/monitor.log"
mkdir -p "$LOG_DIR"

ts() { date '+%Y-%m-%d %H:%M:%S'; }
log() { echo "$(ts) $*" >> "$LOG_FILE"; }
alert() {
    log "ALERT $*"
    logger -t lab-monitor -p user.crit "$*" 2>/dev/null || true
    echo "ALERT $*"
}

# CPU: sample /proc/stat twice, one second apart
read -r _ u1 n1 s1 i1 w1 q1 sq1 _ < /proc/stat
sleep 1
read -r _ u2 n2 s2 i2 w2 q2 sq2 _ < /proc/stat
idle=$(( (i2 + w2) - (i1 + w1) ))
total=$(( (u2 + n2 + s2 + i2 + w2 + q2 + sq2) - (u1 + n1 + s1 + i1 + w1 + q1 + sq1) ))
cpu=$(( total > 0 ? 100 * (total - idle) / total : 0 ))

# Memory: used / total from /proc/meminfo (MemAvailable aware)
mem_total=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
mem_avail=$(awk '/MemAvailable/ {print $2}' /proc/meminfo)
mem=$(( 100 * (mem_total - mem_avail) / mem_total ))

log "INFO cpu=${cpu}% mem=${mem}%"
(( cpu >= CPU_THRESHOLD )) && alert "High CPU on $(hostname): ${cpu}% (threshold ${CPU_THRESHOLD}%)"
(( mem >= MEM_THRESHOLD )) && alert "High memory on $(hostname): ${mem}% (threshold ${MEM_THRESHOLD}%)"

# Disk: every real mounted filesystem
while read -r use mount; do
    use=${use%\%}
    log "INFO disk $mount=${use}%"
    (( use >= DISK_THRESHOLD )) && alert "Disk almost full on $(hostname): $mount at ${use}% (threshold ${DISK_THRESHOLD}%)"
done < <(df -P -x tmpfs -x devtmpfs -x squashfs | awk 'NR>1 {print $5, $6}')

# Services
for svc in $SERVICES; do
    if systemctl is-active --quiet "$svc"; then
        log "INFO service $svc=active"
    else
        alert "Service down on $(hostname): $svc is not active"
    fi
done
