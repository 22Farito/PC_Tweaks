# =================================================================================
#                                   SERVICE TWEAKS
# =================================================================================
function Set-ServiceTweak {
    param (
        [string]$ServiceName,
        [string]$StartupType
    )

    Write-Host "Tweaking: ${ServiceName} -> ${StartupType}" -ForegroundColor Cyan

    try {
        $null = sc.exe config $ServiceName "start=$StartupType" 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[OK] ${ServiceName}: set startup to '${StartupType}'" -ForegroundColor Green
        } else {
            Write-Host "[ERROR] ${ServiceName}: failed (exit code: $LASTEXITCODE)" -ForegroundColor Red
        }
    }
    catch {
        Write-Host "[EXCEPTION] ${ServiceName} -> $($_.Exception.Message)" -ForegroundColor DarkRed
    }
}

# =========================
# Individual Tweaks
# =========================
$ServiceTweaks = @(
    @{ Name = "AJRouter"; Startup = "disabled" }
    @{ Name = "AppVClient"; Startup = "disabled" }
    @{ Name = "DiagTrack"; Startup = "disabled" }
    @{ Name = "DialogBlockingService"; Startup = "disabled" }
    @{ Name = "dmwappushservice"; Startup = "disabled" }
    @{ Name = "RemoteAccess"; Startup = "disabled" }
    @{ Name = "RemoteRegistry"; Startup = "disabled" }
    @{ Name = "shpamsvc"; Startup = "disabled" }
    @{ Name = "ssh-agent"; Startup = "disabled" }
    @{ Name = "tzautoupdate"; Startup = "disabled" }
    @{ Name = "uhssvc"; Startup = "disabled" }
    @{ Name = "UevAgentService"; Startup = "disabled" }
    @{ Name = "SysMain"; Startup = "disabled" }
    @{ Name = "RetailDemo"; Startup = "disabled" }
    @{ Name = "WMPNetworkSvc"; Startup = "disabled" }
    @{ Name = "WalletService"; Startup = "disabled" }
    @{ Name = "PhoneSvc"; Startup = "disabled" }
    @{ Name = "MapsBroker"; Startup = "disabled" }
    @{ Name = "lfsvc"; Startup = "disabled" }
    @{ Name = "CDPSvc"; Startup = "disabled" }
    @{ Name = "CDPUserSvc"; Startup = "disabled" }
    @{ Name = "MessagingService"; Startup = "disabled" }
    @{ Name = "PimIndexMaintenanceSvc"; Startup = "disabled" }
    @{ Name = "UnistoreSvc"; Startup = "disabled" }
    @{ Name = "OneSyncSvc"; Startup = "disabled" }

    # ⚡ Auto
    @{ Name = "AudioEndpointBuilder"; Startup = "auto" }
    @{ Name = "AudioSrv"; Startup = "auto" }
    @{ Name = "BFE"; Startup = "auto" }
    @{ Name = "BthAvctpSvc"; Startup = "auto" }
    @{ Name = "BthHFSrv"; Startup = "auto" }
    @{ Name = "CoreMessagingRegistrar"; Startup = "auto" }
    @{ Name = "CryptSvc"; Startup = "auto" }
    @{ Name = "Dhcp"; Startup = "auto" }
    @{ Name = "Dnscache"; Startup = "auto" }
    @{ Name = "EventLog"; Startup = "auto" }
    @{ Name = "Spooler"; Startup = "auto" }
    @{ Name = "MpsSvc"; Startup = "auto" }
    @{ Name = "RpcEptMapper"; Startup = "auto" }
    @{ Name = "SamSs"; Startup = "auto" }
    @{ Name = "SENS"; Startup = "auto" }
    @{ Name = "WinDefend"; Startup = "auto" }

    # 📦 Manual (demand) examples
    @{ Name = "AppIDSvc"; Startup = "demand" }
    @{ Name = "AppMgmt"; Startup = "demand" }
    @{ Name = "BcastDVRUserService"; Startup = "demand" }
    @{ Name = "BluetoothUserService"; Startup = "demand" }
    @{ Name = "Fax"; Startup = "demand" }
)

$XboxServices = @(
    @{ Name = "XblAuthManager"; Startup = "disabled" }
    @{ Name = "XblGameSave"; Startup = "disabled" }
    @{ Name = "XboxNetApiSvc"; Startup = "disabled" }
)


# =================================================================================
#                                APPLY ALL TWEAKS
# =================================================================================
function Invoke-ServiceTweak {
    param (
        [string]$ServiceName,
        [string]$StartupType
    )

    Write-Host "Tweaking: ${ServiceName} -> ${StartupType}" -ForegroundColor Cyan
    Write-Log "Tweaking: ${ServiceName} -> ${StartupType}"

    try {
        $null = sc.exe config $ServiceName "start=$StartupType" 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[OK] ${ServiceName}: set startup to '${StartupType}'" -ForegroundColor Green
            Write-Log "[OK] ${ServiceName}: set startup to '${StartupType}'"
        } else {
            Write-Host "[ERROR] ${ServiceName}: failed (exit code: $LASTEXITCODE)" -ForegroundColor Red
            Write-Log "[ERROR] ${ServiceName}: failed (exit code: $LASTEXITCODE)"
        }
    }
    catch {
        Write-Host "[EXCEPTION] ${ServiceName} -> $($_.Exception.Message)" -ForegroundColor DarkRed
        Write-Log "[EXCEPTION] ${ServiceName} -> $($_.Exception.Message)"
    }
}