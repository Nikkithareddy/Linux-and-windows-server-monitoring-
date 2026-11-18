# Linux and Windows Server Monitoring and Incident Management Lab

A small virtual lab for practising server monitoring, alerting, routine administration and incident response on Linux (RHEL, Ubuntu) and Windows Server 2019 hosts.

**Tech stack:** RHEL, Ubuntu, Windows Server 2019, Bash, PowerShell, VirtualBox

# Linux and Windows Server Monitoring & Incident Management Lab

A hands-on IT infrastructure operations lab designed to practise server monitoring, system administration, automated alerting, incident simulation, troubleshooting, and incident recovery across Linux and Windows Server environments.

The project demonstrates practical system administration and incident management workflows similar to those used in enterprise IT operations and data center environments.

## 1. Project Overview

In an IT infrastructure environment, servers must remain available, healthy, and secure. CPU or memory spikes, disk-space issues, and stopped services can affect business operations.

This project provides a virtual lab to:

- Monitor CPU, memory, disk utilization, and service health.
- Generate alerts when system thresholds are exceeded.
- Collect system logs for troubleshooting.
- Automate routine administration tasks.
- Simulate infrastructure incidents.
- Investigate root causes and restore services.
- Document incident resolutions using runbooks and knowledge-base templates.

**Objective:** Build practical experience in monitoring, troubleshooting, automation, and incident response across Linux and Windows servers.

## 2. Technologies Used

| Technology | Purpose |
|---|---|
| RHEL / Ubuntu | Linux server administration |
| Windows Server 2019 | Windows server administration |
| Bash | Linux automation and monitoring |
| PowerShell | Windows automation and monitoring |
| VirtualBox | Virtual machine environment |
| Cron | Scheduled Linux monitoring |
| Windows Task Scheduler | Scheduled Windows monitoring |
| System logs | Incident investigation and troubleshooting |

## 3. Project Architecture

The lab uses separate Linux and Windows virtual machines.

```text
                 IT OPERATIONS LAB
                         |
             +-----------+-----------+
             |                       |
        Linux Server             Windows Server
       RHEL / Ubuntu             Windows Server 2019
             |                       |
       Bash Scripts             PowerShell Scripts
             |                       |
     +-------+-------+        +------+-------+
     |       |       |        |      |       |
   CPU    Memory   Disk     CPU   Memory   Disk
     |       |       |        |      |       |
     +-------+-------+        +------+-------+
             |                       |
       Service Checks           Service Checks
             |                       |
        Monitoring                Monitoring
             |                       |
         Alerts                    Alerts
             |                       |
       Log Collection           Log Collection
             |                       |
             +-----------+-----------+
                         |
                 Incident Management
                         |
                Root Cause Analysis
                         |
                 Incident Resolution
                         |
                Runbooks / Knowledge Base
```

## 4. Repository Structure

```text
Linux-and-windows-server-monitoring-/
│
├── linux/
│   ├── monitor.sh
│   ├── collect_logs.sh
│   ├── user_mgmt.sh
│   └── service_restart.sh
│
├── windows/
│   ├── Monitor-Server.ps1
│   ├── Collect-Logs.ps1
│   ├── Manage-Users.ps1
│   └── Restart-MonitoredService.ps1
│
├── simulations/
│   ├── simulate_incidents.sh
│   └── Simulate-Incidents.ps1
│
├── runbooks/
│
├── kb/
│
└── README.md
```

### Folder Explanation

**linux/**

Contains Bash scripts for Linux server monitoring, log collection, user management, and service restart operations.

**windows/**

Contains PowerShell scripts for Windows server monitoring, log collection, user administration, and service restart operations.

**simulations/**

Contains scripts to simulate infrastructure problems, including high CPU utilization, disk-space issues, and stopped services.

**runbooks/**

Contains step-by-step procedures for investigating and resolving incidents.

**kb/**

Contains knowledge-base templates for documenting incident findings, root causes, and resolutions.

## 5. Lab Environment Setup

### Requirements

- Oracle VirtualBox
- One RHEL or Ubuntu virtual machine
- One Windows Server 2019 virtual machine
- Administrative access to both virtual machines
- Git installed on your host machine

### Step 1: Clone the Repository

Open your terminal:

```bash
git clone https://github.com/Nikkithareddy/Linux-and-windows-server-monitoring-.git
```

Navigate to the project:

```bash
cd Linux-and-windows-server-monitoring-
```

### Step 2: Configure the Virtual Machines

Create two virtual machines in VirtualBox:

1. Linux VM – RHEL or Ubuntu.
2. Windows VM – Windows Server 2019.

Configure them using a Host-Only or NAT network.

Copy the `linux/` folder to the Linux VM and the `windows/` folder to the Windows VM.

Keep the incident simulation scripts available in your host or copy them to the corresponding lab VM.

**Important:** Run incident simulations only inside your isolated lab virtual machines. Never execute resource-intensive simulations on production systems.

## 6. Linux Server Monitoring

The Linux monitoring component uses Bash scripts to monitor system health and perform routine administration.

### Step 1: Prepare the Scripts

On the Linux VM:

```bash
sudo mkdir -p /opt/lab-monitor
```

Copy the Linux scripts into the monitoring directory, then execute:

```bash
sudo chmod +x /opt/lab-monitor/*.sh
```

### Step 2: Run the Monitoring Script

```bash
sudo /opt/lab-monitor/monitor.sh
```

The script checks:

- CPU utilization
- Memory utilization
- Disk utilization
- Configured service status

Thresholds and monitored services can be configured using environment variables.

Example:

```bash
sudo CPU_THRESHOLD=70 \
SERVICES="sshd httpd" \
/opt/lab-monitor/monitor.sh
```

For Ubuntu, use the appropriate service names, such as `ssh` and `cron`.

### Step 3: Configure Scheduled Monitoring

Linux uses Cron to execute monitoring scripts automatically.

Open the root crontab:

```bash
sudo crontab -e
```

Add:

```cron
* * * * * /opt/lab-monitor/monitor.sh
```

This schedules monitoring every minute.

### Step 4: Check Monitoring Logs

```bash
sudo tail -f /var/log/lab-monitor/monitor.log
```

Check system journal alerts:

```bash
sudo journalctl -t lab-monitor
```

These logs help identify abnormal system conditions and investigate potential incidents.

## 7. Windows Server Monitoring

The Windows monitoring component uses PowerShell scripts.

### Step 1: Prepare the Monitoring Directory

Open PowerShell as Administrator:

```powershell
New-Item -ItemType Directory C:\LabMonitor -Force
```

Copy the scripts from the repository's `windows/` directory into `C:\LabMonitor`.

### Step 2: Execute the Monitoring Script

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File C:\LabMonitor\Monitor-Server.ps1
```

The monitoring script checks Windows server health and records monitoring information.

### Step 3: Configure Windows Task Scheduler

Run PowerShell as Administrator:

```powershell
$action = New-ScheduledTaskAction `
-Execute 'powershell.exe' `
-Argument '-NoProfile -ExecutionPolicy Bypass -File C:\LabMonitor\Monitor-Server.ps1'

$trigger = New-ScheduledTaskTrigger `
-Once -At (Get-Date) `
-RepetitionInterval (New-TimeSpan -Minutes 1)

Register-ScheduledTask `
-TaskName 'LabMonitor' `
-Action $action `
-Trigger $trigger `
-User 'SYSTEM' `
-RunLevel Highest
```

This configures the monitoring script to execute every minute.

### Step 4: Review Monitoring Logs

```powershell
Get-Content C:\LabMonitor\monitor.log -Tail 20
```

Monitoring alerts are also written to the Windows Application event log using the `LabMonitor` source and event ID `1001`.

## 8. Routine System Administration

The project also includes scripts to automate common administration tasks.

### Linux User Management

Create a user:

```bash
sudo ./linux/user_mgmt.sh add jdoe wheel
```

Audit user accounts and administrative group membership:

```bash
sudo ./linux/user_mgmt.sh audit
```

### Linux Log Collection

```bash
sudo ./linux/collect_logs.sh
```

The script bundles system logs into a compressed archive under `/tmp/`.

### Windows User Management

Create a Windows user:

```powershell
.\windows\Manage-Users.ps1 -Action Add -UserName jdoe -Group 'Remote Desktop Users'
```

Audit user accounts:

```powershell
.\windows\Manage-Users.ps1 -Action Audit
```

### Windows Log Collection

```powershell
.\windows\Collect-Logs.ps1
```

These scripts help practise user administration, log collection, and routine operational tasks.

## 9. Incident Simulation and Troubleshooting

One of the main features of this project is the ability to simulate infrastructure incidents and practise resolving them.

The lab covers three scenarios.

| Incident | Possible impact | Monitoring focus |
|---|---|---|
| High CPU utilization | Slow server performance | CPU threshold |
| Disk-space exhaustion | Application or service failures | Disk utilization |
| Stopped service | Service unavailability | Service health |

### Step 1: Start Monitoring

On the target Linux VM, execute:

```bash
sudo /opt/lab-monitor/monitor.sh
```

For Windows, execute the corresponding PowerShell monitoring script.

### Step 2: Simulate an Incident

Linux examples:

```bash
sudo ./simulations/simulate_incidents.sh cpu
```

```bash
sudo ./simulations/simulate_incidents.sh disk
```

```bash
sudo ./simulations/simulate_incidents.sh service sshd
```

Windows examples:

```powershell
.\simulations\Simulate-Incidents.ps1 -Scenario Cpu
```

```powershell
.\simulations\Simulate-Incidents.ps1 -Scenario Disk
```

```powershell
.\simulations\Simulate-Incidents.ps1 -Scenario Service
```

Run only one simulation at a time and review the script before execution.

### Step 3: Detect the Incident

Check the monitoring logs:

```bash
sudo tail -f /var/log/lab-monitor/monitor.log
```

The monitoring system records alerts when configured conditions are detected.

### Step 4: Investigate the Root Cause

For a stopped Linux service:

```bash
systemctl status sshd
```

Review service logs:

```bash
sudo journalctl -u sshd -n 20
```

For disk issues:

```bash
df -h
```

For memory:

```bash
free -h
```

For CPU and running processes:

```bash
top
```

These commands help investigate the source of the issue before attempting recovery.

### Step 5: Resolve the Incident

For a stopped service:

```bash
sudo systemctl restart sshd
```

Verify recovery:

```bash
systemctl status sshd
```

For other incidents, follow the appropriate recovery procedure documented in the `runbooks/` directory.

### Step 6: Document the Incident

After resolving the issue:

1. Record the incident type.
2. Document the symptoms.
3. Identify the root cause.
4. Record the troubleshooting steps.
5. Document the resolution.
6. Add preventive measures.

Use the templates available in the `kb/` directory.

## 10. Incident Response Workflow

The project follows a practical incident management workflow:

```text
System Monitoring
       |
       v
Incident Detection
       |
       v
Alert Generation
       |
       v
Log Investigation
       |
       v
Root Cause Analysis
       |
       v
Incident Resolution
       |
       v
Service Recovery Verification
       |
       v
Knowledge Base Documentation
```

This workflow demonstrates the importance of detecting incidents early, investigating their causes, restoring services, and documenting solutions.

## 11. Key Learning Outcomes

Through this project, I practised:

- Linux and Windows server administration.
- Bash and PowerShell scripting.
- CPU, memory, disk, and service monitoring.
- Automated task scheduling.
- System log collection and analysis.
- User and permission management.
- Incident simulation and troubleshooting.
- Root-cause analysis.
- Service recovery and verification.
- Technical documentation and runbook creation.

## 12. Future Improvements

Potential enhancements include:

- Centralized monitoring dashboards.
- Email or messaging-based alert notifications.
- Integration with enterprise monitoring tools such as Zabbix.
- Automated incident ticket creation.
- Historical performance reporting.
- Integration with configuration management tools such as Ansible.

## 13. Project Summary

This project demonstrates a practical approach to monitoring and managing Linux and Windows infrastructure in a controlled virtual environment.

By combining automated monitoring, incident simulation, log analysis, troubleshooting, and documentation, the lab provides hands-on exposure to essential IT operations and infrastructure support activities.

**GitHub Repository:**  
https://github.com/Nikkithareddy/Linux-and-windows-server-monitoring-

**Technologies:** RHEL, Ubuntu, Windows Server 2019, Bash, PowerShell, VirtualBox.
