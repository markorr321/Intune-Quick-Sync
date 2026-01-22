# Restart the IME service to reset the random delay timers
Restart-Service IntuneManagementExtension -Force

# Wait for the service to fully start and write initial log entries
Start-Sleep -Seconds 5

# Trigger an immediate check-in with Intune to get latest app/policy assignments
explorer.exe "intunemanagementextension://syncapp"

# Wait for the sync trigger to complete and log entries to be written
Start-Sleep -Seconds 5

# Set up variables - path to IME log and current time for calculations
$LogPath = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log"
$Now = Get-Date

# Search the log for delay timer entries, get the 3 most recent (one per workload)
Select-String -Path $LogPath -Pattern "set timer, delayed seconds = (\d+) for workload (\w+)" |
    Select-Object -Last 3 |
    ForEach-Object {
        # Extract the seconds and workload name from each log line
        if ($_.Line -match "delayed seconds = (\d+) for workload (\w+)") {
            $Seconds = [int]$Matches[1]
            $Workload = $Matches[2]

            # Calculate the actual clock time when processing will start
            $InstallTime = $Now.AddSeconds($Seconds)

            # Convert raw seconds into minutes and seconds for readable output
            $Minutes = [math]::Floor($Seconds / 60)
            $Secs = $Seconds % 60

            Write-Host "$Workload will process at $($InstallTime.ToString('HH:mm:ss')) (in $Minutes min $Secs sec)" -ForegroundColor Cyan
        }
    }
