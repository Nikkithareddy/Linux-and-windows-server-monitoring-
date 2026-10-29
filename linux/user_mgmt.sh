#!/usr/bin/env bash
# user_mgmt.sh - create, lock, unlock and remove local users, and manage group access.
# Usage:
#   sudo ./user_mgmt.sh add <user> [group]
#   sudo ./user_mgmt.sh lock <user>
#   sudo ./user_mgmt.sh unlock <user>
#   sudo ./user_mgmt.sh remove <user>
#   sudo ./user_mgmt.sh grant <user> <group>
#   sudo ./user_mgmt.sh audit
set -eu

LOG=/var/log/lab-monitor/user_mgmt.log
mkdir -p "$(dirname "$LOG")"
note() { echo "$(date '+%F %T') $(logname 2>/dev/null || echo root) $*" >> "$LOG"; }

[ "$(id -u)" -eq 0 ] || { echo "Run as root."; exit 1; }
action=${1:-}

case "$action" in
    add)
        user=${2:?user required}; group=${3:-}
        id "$user" &>/dev/null && { echo "$user already exists"; exit 1; }
        useradd -m -s /bin/bash "$user"
        passwd -e "$user" >/dev/null   # force password change at first login
        [ -n "$group" ] && usermod -aG "$group" "$user"
        note "added user $user group=${group:-none}"
        echo "User $user created. Set a password with: passwd $user" ;;
    lock)    usermod -L "${2:?user required}"; note "locked ${2}"; echo "Locked ${2}" ;;
    unlock)  usermod -U "${2:?user required}"; note "unlocked ${2}"; echo "Unlocked ${2}" ;;
    remove)  userdel -r "${2:?user required}"; note "removed ${2}"; echo "Removed ${2}" ;;
    grant)   usermod -aG "${3:?group required}" "${2:?user required}"; note "granted ${2} -> ${3}"; echo "Added ${2} to ${3}" ;;
    audit)
        echo "Users with login shells:"
        awk -F: '$7 !~ /(nologin|false)$/ {print " - " $1 " (uid " $3 ")"}' /etc/passwd
        echo; echo "Members of sudo/wheel:"
        getent group wheel sudo | awk -F: '{print " - " $1 ": " $4}' ;;
    *) echo "Usage: $0 {add|lock|unlock|remove|grant|audit} ..."; exit 1 ;;
esac
