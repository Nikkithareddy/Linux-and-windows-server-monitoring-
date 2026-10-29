# Linux and Windows Server Monitoring and Incident Management Lab

A small virtual lab for practising server monitoring, alerting, routine administration and incident response on Linux (RHEL, Ubuntu) and Windows Server 2019 hosts.

**Tech stack:** RHEL, Ubuntu, Windows Server 2019, Bash, PowerShell, VirtualBox

## What is in this repo

| Folder | Contents |
|--------|----------|
| `linux/` | `monitor.sh` (CPU, memory, disk, service checks with alerts), `collect_logs.sh`, `user_mgmt.sh`, `service_restart.sh` |
| `windows/` | `Monitor-Server.ps1`, `Collect-Logs.ps1`, `Manage-Users.ps1`, `Restart-MonitoredService.ps1` |
| `simulations/` | Scripts that trigger high CPU, a full disk and a stopped service on a lab VM |
| `runbooks/` | Step-by-step response procedures for each incident type |
| `kb/` | Knowledge base article templates to fill in after each simulated incident |

## Lab setup

1. In VirtualBox, create one RHEL (or Ubuntu) VM and one Windows Server 2019 VM on a host-only or NAT network.
2. Copy `linux/` to the Linux VM and `windows/` to the Windows VM.
3. Never run the `simulations/` scripts on anything except these lab VMs.

## Monitoring

### Linux (cron, every minute)

```bash
sudo mkdir -p /opt/lab-monitor && sudo cp linux/*.sh /opt/lab-monitor/ && sudo chmod +x /opt/lab-monitor/*.sh
sudo crontab -e
```
```
* * * * * /opt/lab-monitor/monitor.sh
* * * * * /opt/lab-monitor/service_restart.sh sshd
```

Thresholds and services are set with environment variables, for example `CPU_THRESHOLD=70 SERVICES="sshd httpd" ./monitor.sh`. On Ubuntu the service names are `ssh` and `cron`. Logs go to `/var/log/lab-monitor/monitor.log`, and alerts are also sent to syslog (`journalctl -t lab-monitor`).

### Windows (Task Scheduler, every minute)

```powershell
New-Item -ItemType Directory C:\LabMonitor -Force
Copy-Item .\windows\*.ps1 C:\LabMonitor\
$action  = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument '-NoProfile -ExecutionPolicy Bypass -File C:\LabMonitor\Monitor-Server.ps1'
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 1)
Register-ScheduledTask -TaskName 'LabMonitor' -Action $action -Trigger $trigger -User 'SYSTEM' -RunLevel Highest
```

Logs go to `C:\LabMonitor\monitor.log`, and alerts are also written to the Windows Application event log (source `LabMonitor`, event ID 1001).

## Administration scripts

```bash
sudo ./linux/user_mgmt.sh add jdoe wheel        # create user, force password change
sudo ./linux/user_mgmt.sh audit                 # list login users and sudo/wheel members
sudo ./linux/collect_logs.sh                    # bundle logs into /tmp/logs_<host>_<time>.tar.gz
```
```powershell
.\windows\Manage-Users.ps1 -Action Add -UserName jdoe -Group 'Remote Desktop Users'
.\windows\Manage-Users.ps1 -Action Audit
.\windows\Collect-Logs.ps1
```

## Incident simulation workflow

1. Start the monitor on the target VM.
2. Trigger an incident:
   - Linux: `sudo ./simulations/simulate_incidents.sh cpu | disk | service sshd`
   - Windows: `.\simulations\Simulate-Incidents.ps1 -Scenario Cpu | Disk | Service`
3. Watch the alert appear in `monitor.log`.
4. Follow the matching runbook in `runbooks/`, find the root cause from the logs and fix it.
5. Record what you found in the matching KB template in `kb/`.

## Notes

- Scripts are written for a lab. Review the thresholds, paths and permissions before adapting them to anything else.
- `kb/` files are templates. Fill them in with your own findings from each simulation.
