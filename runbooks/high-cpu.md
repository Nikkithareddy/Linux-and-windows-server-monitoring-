# Runbook: High CPU

**Alert:** `High CPU on <host>: <n>% (threshold 85%)` from `monitor.sh` / `Monitor-Server.ps1`

## 1. Confirm
- Linux: `top -b -n1 | head -15` or `ps aux --sort=-%cpu | head`
- Windows: `Get-Process | Sort-Object CPU -Descending | Select-Object -First 10`
- Check whether the load is sustained (several consecutive log entries) or a short spike.

## 2. Identify the cause
- Which process or service is using the CPU, and is it expected (backup, patching, batch job)?
- Did it start after a deployment, update or config change? Check `journalctl --since "1 hour ago"` / Event Viewer.

## 3. Resolve
- Expected workload: leave it, note the schedule, consider moving the job off-hours.
- Runaway process: try a graceful stop first (`systemctl restart <svc>` / `Restart-Service`), then `kill` / `Stop-Process` only if it does not respond.
- Repeated cause: raise it for capacity review.

## 4. Verify and record
- CPU back under threshold for 5+ minutes in `monitor.log`.
- Write the cause and fix in a KB article (`kb/high-cpu-process.md`).
