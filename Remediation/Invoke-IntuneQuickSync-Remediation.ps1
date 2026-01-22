<#
.SYNOPSIS
    Intune Proactive Remediation - Triggers Intune sync and logs scheduled workload times.

.DESCRIPTION
    This remediation script restarts the Intune Management Extension service to reset
    delay timers, triggers an immediate sync, and logs the scheduled processing times
    for each workload to a local log file.

.NOTES
    Deploy as a Proactive Remediation without a detection script (or use a detection
    script that always exits with code 1 to ensure this runs).

    Run as: System
    Run in 64-bit PowerShell: Yes
#>

$LogFolder = "$env:SystemRoot\Temp\IntuneQuickSync"
$LogFile = "$LogFolder\IntuneQuickSync.log"

# Create log folder if it doesn't exist
if (-not (Test-Path $LogFolder)) {
    New-Item -Path $LogFolder -ItemType Directory -Force | Out-Null
}

function Write-Log {
    param([string]$Message)
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$Timestamp - $Message" | Out-File -FilePath $LogFile -Append -Encoding UTF8
}

try {
    Write-Log "========== Intune Quick Sync Started =========="

    # Restart the IME service to reset the random delay timers
    Write-Log "Restarting IntuneManagementExtension service..."
    Restart-Service IntuneManagementExtension -Force -ErrorAction Stop
    Write-Log "Service restarted successfully."

    # Wait for the service to fully start
    Start-Sleep -Seconds 5

    # Trigger an immediate check-in with Intune
    Write-Log "Triggering Intune sync..."
    Start-Process "explorer.exe" -ArgumentList "intunemanagementextension://syncapp"
    Write-Log "Sync triggered."

    # Wait for sync to complete and log entries to be written
    Start-Sleep -Seconds 5

    # Parse the IME log for scheduled workload times
    $IMELogPath = "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log"
    $Now = Get-Date

    Write-Log "Parsing scheduled workload times..."

    $ScheduleEntries = Select-String -Path $IMELogPath -Pattern "set timer, delayed seconds = (\d+) for workload (\w+)" |
        Select-Object -Last 3

    if ($ScheduleEntries) {
        foreach ($Entry in $ScheduleEntries) {
            if ($Entry.Line -match "delayed seconds = (\d+) for workload (\w+)") {
                $Seconds = [int]$Matches[1]
                $Workload = $Matches[2]
                $InstallTime = $Now.AddSeconds($Seconds)
                $Minutes = [math]::Floor($Seconds / 60)
                $Secs = $Seconds % 60

                Write-Log "$Workload scheduled for $($InstallTime.ToString('yyyy-MM-dd HH:mm:ss')) (in $Minutes min $Secs sec)"
            }
        }
    } else {
        Write-Log "No workload schedule entries found in IME log."
    }

    Write-Log "========== Intune Quick Sync Completed =========="

    Write-Output "Intune Quick Sync completed successfully. Log: $LogFile"
    exit 0
}
catch {
    Write-Log "ERROR: $($_.Exception.Message)"
    Write-Output "Failed: $($_.Exception.Message)"
    exit 1
}
