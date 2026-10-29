<#
.SYNOPSIS
    Collects the logs and system state needed for troubleshooting into one zip file.
#>
param([string]$OutDir = 'C:\LabMonitor\collected')

$stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$work  = Join-Path $OutDir "logs_${env:COMPUTERNAME}_$stamp"
New-Item -ItemType Directory -Path $work -Force | Out-Null

# Last 24 hours of errors/warnings from the System and Application logs
$since = (Get-Date).AddHours(-24)
foreach ($log in 'System', 'Application') {
    Get-WinEvent -FilterHashtable @{ LogName = $log; Level = 1, 2, 3; StartTime = $since } -ErrorAction SilentlyContinue |
        Select-Object TimeCreated, Id, LevelDisplayName, ProviderName, Message |
        Export-Csv -Path (Join-Path $work "$log-events-24h.csv") -NoTypeInformation
}

Get-Service | Where-Object Status -ne 'Running' |
    Select-Object Name, DisplayName, Status, StartType |
    Export-Csv (Join-Path $work 'stopped-services.csv') -NoTypeInformation

Get-CimInstance Win32_LogicalDisk -Filter 'DriveType=3' |
    Select-Object DeviceID, @{n='SizeGB';e={[math]::Round($_.Size/1GB,1)}}, @{n='FreeGB';e={[math]::Round($_.FreeSpace/1GB,1)}} |
    Export-Csv (Join-Path $work 'disk-usage.csv') -NoTypeInformation

Get-Process | Sort-Object CPU -Descending | Select-Object -First 20 Name, Id, CPU, WS |
    Export-Csv (Join-Path $work 'top-cpu-processes.csv') -NoTypeInformation

if (Test-Path 'C:\LabMonitor\monitor.log') { Copy-Item 'C:\LabMonitor\monitor.log' $work }

Compress-Archive -Path "$work\*" -DestinationPath "$work.zip" -Force
Remove-Item $work -Recurse -Force
Write-Output "Created $work.zip"
