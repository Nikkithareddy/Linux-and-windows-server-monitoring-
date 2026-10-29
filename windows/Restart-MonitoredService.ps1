<#
.SYNOPSIS
    Restarts a service if it is not running and records the result.
.DESCRIPTION
    Gives up after MaxTries attempts so a crash-looping service is escalated to a
    person instead of being restarted forever.
#>
param(
    [Parameter(Mandatory)][string]$ServiceName,
    [int]$MaxTries = 3,
    [string]$LogFile = 'C:\LabMonitor\service_restart.log'
)

New-Item -ItemType Directory -Path (Split-Path $LogFile) -Force | Out-Null
function Write-Log([string]$m) { "{0} {1}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $m | Add-Content $LogFile }

$svc = Get-Service -Name $ServiceName -ErrorAction Stop
if ($svc.Status -eq 'Running') { return }

Write-Log "WARN $ServiceName is $($svc.Status), attempting restart"
for ($i = 1; $i -le $MaxTries; $i++) {
    try { Restart-Service -Name $ServiceName -Force -ErrorAction Stop } catch { Write-Log "WARN attempt $i failed: $_" }
    Start-Sleep -Seconds 3
    if ((Get-Service -Name $ServiceName).Status -eq 'Running') {
        Write-Log "OK $ServiceName recovered on attempt $i"
        return
    }
}
Write-Log "CRIT $ServiceName failed to restart after $MaxTries attempts - manual action needed"
exit 1
