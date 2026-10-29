<#
.SYNOPSIS
    Create, disable, enable and remove local users and manage local group membership.
.EXAMPLE
    .\Manage-Users.ps1 -Action Add -UserName jdoe -Group 'Remote Desktop Users'
.EXAMPLE
    .\Manage-Users.ps1 -Action Audit
#>
#Requires -RunAsAdministrator
param(
    [Parameter(Mandatory)][ValidateSet('Add', 'Disable', 'Enable', 'Remove', 'Grant', 'Audit')][string]$Action,
    [string]$UserName,
    [string]$Group
)

$logFile = 'C:\LabMonitor\user_mgmt.log'
New-Item -ItemType Directory -Path (Split-Path $logFile) -Force | Out-Null
function Note([string]$m) { "{0} {1} {2}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $env:USERNAME, $m | Add-Content $logFile }

switch ($Action) {
    'Add' {
        $pw = Read-Host "Temporary password for $UserName" -AsSecureString
        New-LocalUser -Name $UserName -Password $pw -PasswordNeverExpires:$false -UserMayNotChangePassword:$false | Out-Null
        # Force a password change at first logon
        net user $UserName /logonpasswordchg:yes | Out-Null
        if ($Group) { Add-LocalGroupMember -Group $Group -Member $UserName }
        Note "added $UserName group=$Group"
        Write-Output "User $UserName created." }
    'Disable' { Disable-LocalUser -Name $UserName; Note "disabled $UserName"; Write-Output "Disabled $UserName" }
    'Enable'  { Enable-LocalUser  -Name $UserName; Note "enabled $UserName";  Write-Output "Enabled $UserName" }
    'Remove'  { Remove-LocalUser  -Name $UserName; Note "removed $UserName";  Write-Output "Removed $UserName" }
    'Grant'   { Add-LocalGroupMember -Group $Group -Member $UserName; Note "granted $UserName -> $Group"; Write-Output "Added $UserName to $Group" }
    'Audit'   {
        Write-Output 'Local users:'
        Get-LocalUser | Select-Object Name, Enabled, LastLogon | Format-Table -AutoSize
        Write-Output 'Administrators group:'
        Get-LocalGroupMember -Group 'Administrators' | Select-Object Name, ObjectClass | Format-Table -AutoSize }
}
