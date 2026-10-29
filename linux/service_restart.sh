#!/usr/bin/env bash
# service_restart.sh - restart a service if it is not running and record the result.
# Meant to run from cron after monitor.sh. Gives up after MAX_TRIES attempts so a
# crash-looping service is escalated to a human instead of restarted forever.
# Usage: sudo ./service_restart.sh <service> [max_tries]
set -u

svc=${1:?service name required}
MAX_TRIES=${2:-3}
LOG=/var/log/lab-monitor/service_restart.log
mkdir -p "$(dirname "$LOG")"
log() { echo "$(date '+%F %T') $*" >> "$LOG"; }

if systemctl is-active --quiet "$svc"; then
    exit 0
fi

log "WARN $svc is down, attempting restart"
for ((i = 1; i <= MAX_TRIES; i++)); do
    systemctl restart "$svc"
    sleep 3
    if systemctl is-active --quiet "$svc"; then
        log "OK $svc recovered on attempt $i"
        exit 0
    fi
done

log "CRIT $svc failed to restart after $MAX_TRIES attempts - manual action needed"
logger -t lab-monitor -p user.crit "$svc failed to restart after $MAX_TRIES attempts"
exit 1
