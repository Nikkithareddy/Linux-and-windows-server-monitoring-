# Runbook: Disk Almost Full

**Alert:** `Disk almost full on <host>: <mount> at <n>% (threshold 90%)`

## 1. Confirm
- Linux: `df -h`, then `du -xh <mount> --max-depth=2 | sort -rh | head -20`
- Windows: `Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3"`

## 2. Find what is using the space
- Linux: large files in `/var/log`, `/var/tmp`, `/tmp`; deleted-but-open files via `lsof +L1`.
- Windows: `C:\Windows\Temp`, user temp folders, old logs, `C:\Windows\SoftwareDistribution\Download`.

## 3. Free space safely
- Remove files that are clearly temporary or already backed up. Do not delete anything you cannot identify.
- Compress or rotate logs (`logrotate -f /etc/logrotate.conf`).
- If it keeps growing, the fix is rotation, a quota or more disk, not repeated cleanup.

## 4. Verify and record
- Usage back under threshold and stable in `monitor.log`.
- Record the cause and the permanent fix in `kb/disk-full.md`.
