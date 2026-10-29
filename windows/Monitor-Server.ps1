<#
.SYNOPSIS
    Health check for CPU, memory, disk and service status on Windows Server 2019.
.DESCRIPTION
    Logs every run and writes an ALERT line (and a Windows Application event) when a
    threshold is crossed. Schedule it with Task Scheduler (see README).
#>
param(
    [int]$CpuThreshold  = 85,
    [int]$MemThreshold  = 85,
    [int]$DiskThreshold = 90,
    [string[]]$Services = @('W32Time', 'Spooler', 'WinRM'),
    [string]$LogDir     = 'C:\LabMonitor'
)

New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
$logFile = Join-Path $LogDir 'monitor.log'

function Write-Log([string]$Level, [string]$Message) {
    "{0} {1} {2}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Level, $Message |
        Add-Content -Path $logFile
}

function Send-Alert([string]$Message) {
    Write-Log 'ALERT' $Message
    Write-Output "ALERT $Message"
    try {
        if (-not [System.Diagnostics.EventLog]::SourceExists('LabMonitor')) {
            New-EventLog -LogName Application -Source 'LabMonitor'
        }
        Write-EventLog -LogName Application -Source 'LabMonitor' -EntryType Error -EventId 1001 -Message $Message
    } catch { Write-Log 'WARN' "Could not write event log: $_" }
}

$computer = $env:COMPUTERNAME

# CPU
$cpu = [math]::Round((Get-Counter '\Processor(_Total)\% Processor Time' -SampleInterval 1 -MaxSamples 3 |
        Select-Object -ExpandProperty CounterSamples |
        Measure-Object -Property CookedValue -Average).Average)

# Memory
$os  = Get-CimInstance Win32_OperatingSystem
$mem = [math]::Round(100 * ($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / $os.TotalVisibleMemorySize)

Write-Log 'INFO' "cpu=$cpu% mem=$mem%"
if ($cpu -ge $CpuThreshold) { Send-Alert "High CPU on ${computer}: $cpu% (threshold $CpuThreshold%)" }
if ($mem -ge $MemThreshold) { Send-Alert "High memory on ${computer}: $mem% (threshold $MemThreshold%)" }

# Disk (local fixed disks only)
Get-CimInstance Win32_LogicalDisk -Filter 'DriveType=3' | ForEach-Object {
    $used = [math]::Round(100 * ($_.Size - $_.FreeSpace) / $_.Size)
    Write-Log 'INFO' "disk $($_.DeviceID)=$used%"
    if ($used -ge $DiskThreshold) {
        Send-Alert "Disk almost full on ${computer}: $($_.DeviceID) at $used% (threshold $DiskThreshold%)"
    }
}

# Services
foreach ($name in $Services) {
    $svc = Get-Service -Name $name -ErrorAction SilentlyContinue
    if ($null -eq $svc) { Write-Log 'WARN' "service $name not found"; continue }
    if ($svc.Status -eq 'Running') { Write-Log 'INFO' "service $name=Running" }
    else { Send-Alert "Service down on ${computer}: $name is $($svc.Status)" }
}
