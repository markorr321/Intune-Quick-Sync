# Intune Quick Sync

Resets Intune Management Extension delay timers and triggers an immediate device sync. After syncing, displays the scheduled processing times for Win32App, WinGetApp, and Script workloads.

## Why?

When the Intune Management Extension (IME) checks in, it assigns random delay timers to each workload to stagger processing across your device fleet. This can result in delays of up to 60 minutes before apps or scripts actually install.

This script resets those timers by restarting the IME service and triggering a fresh sync, then shows you exactly when each workload will be processed.

## Scripts

### Interactive Script

**[Invoke-IntuneQuickSync.ps1](Invoke-IntuneQuickSync.ps1)** - Run manually for immediate results.

```powershell
.\Invoke-IntuneQuickSync.ps1
```

**Output:**
```
Win32App will process at 14:32:15 (in 2 min 30 sec)
WinGetApp will process at 14:35:42 (in 5 min 57 sec)
Script will process at 14:31:08 (in 1 min 23 sec)
```

### Proactive Remediation

**[Remediation/Invoke-IntuneQuickSync-Remediation.ps1](Remediation/Invoke-IntuneQuickSync-Remediation.ps1)** - Deploy via Intune Proactive Remediations.

**Deployment Settings:**
| Setting | Value |
|---------|-------|
| Run this script using the logged-on credentials | No |
| Enforce script signature check | No |
| Run script in 64-bit PowerShell | Yes |

**Log Location:** `C:\Windows\Temp\IntuneQuickSync\IntuneQuickSync.log`

## How It Works

1. Restarts the `IntuneManagementExtension` service to reset delay timers
2. Triggers a sync via `intunemanagementextension://syncapp`
3. Parses the IME log to find scheduled workload times
4. Displays (or logs) when each workload will be processed

## Requirements

- Windows 10/11 with Intune enrollment
- Administrator privileges
- Intune Management Extension installed
