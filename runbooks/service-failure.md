# Runbook: Service Failure

**Alert:** `Service down on <host>: <service> ...`

## 1. Confirm
- Linux: `systemctl status <svc>` and `journalctl -u <svc> -n 50 --no-pager`
- Windows: `Get-Service <svc>` and `Get-WinEvent -FilterHashtable @{LogName='System'; ProviderName='Service Control Manager'} -MaxEvents 20`

## 2. Recover
- Try the restart script: `service_restart.sh <svc>` / `Restart-MonitoredService.ps1 -ServiceName <svc>`.
- It tries 3 times; if it logs `CRIT ... manual action needed`, do not keep restarting. Go to step 3.

## 3. Find the root cause
- Read the last log lines before the failure (config error, missing dependency, port in use, out of memory, full disk).
- Check recent changes: package updates, config edits, permission changes.
- Check dependencies: is a required service or mount down?

## 4. Verify and record
- Service stays active across several `monitor.log` entries.
- Record the cause and fix in `kb/service-failure.md`.
