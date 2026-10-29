<#
.SYNOPSIS
    Triggers the three lab incidents on a LAB VM ONLY. Never run on a real server.
.EXAMPLE
    .\Simulate-Incidents.ps1 -Scenario Cpu
    .\Simulate-Incidents.ps1 -Scenario Service -ServiceName Spooler
#>
#Requires -RunAsAdministrator
param(
    [Parameter(Mandatory)][ValidateSet('Cpu', 'Disk', 'Service')][string]$Scenario,
    [string]$ServiceName = 'Spooler',
    [int]$Seconds = 120
)

switch ($Scenario) {
    'Cpu' {
        $cores = [Environment]::ProcessorCount
        Write-Output "Loading $cores cores for $Seconds seconds..."
        $jobs = 1..$cores | ForEach-Object {
            Start-Job -ScriptBlock { param($s) $end = (Get-Date).AddSeconds($s); while ((Get-Date) -lt $end) { 1..10000 | ForEach-Object { [math]::Sqrt($_) } | Out-Null } } -ArgumentList $Seconds
        }
        $jobs | Wait-Job | Remove-Job
    }
    'Disk' {
        $drive = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
        $fillBytes = [int64]($drive.FreeSpace - 0.05 * $drive.Size)
        if ($fillBytes -le 0) { Write-Output 'Already above 95% used.'; return }
        $file = 'C:\Windows\Temp\lab_fill.img'
        Write-Output "Writing $([math]::Round($fillBytes/1GB,2)) GB to $file"
        fsutil file createnew $file $fillBytes | Out-Null
        Write-Output "Clean up with: Remove-Item $file"
    }
    'Service' {
        Write-Output "Stopping $ServiceName"
        Stop-Service -Name $ServiceName -Force
        Write-Output "Recover with: Start-Service $ServiceName (or let Restart-MonitoredService.ps1 do it)"
    }
}
