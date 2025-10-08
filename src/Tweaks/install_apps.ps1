# =================================================================================
#                                   INSTALL APPS
# =================================================================================

function Install-App {
    param (
        [string]$AppId,
        [string]$AppName
    )

    Write-Host "Installing $AppName..."
    $command = "winget install --id $AppId -e --silent"

    try {
        Invoke-Expression $command 2>&1 | Out-String
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[SUCCESS] $AppName installed"
        }
        else {
            Write-Host "[ERROR] $AppName failed with exit code $LASTEXITCODE"
        }
    }
    catch {
        Write-Host "[EXCEPTION] $AppName -> $($_.Exception.Message)"
    }
}

# =========================
# Individual Install
# =========================

# Browsers
function Install-Chrome { Install-App -AppId "Google.Chrome" -AppName "Google Chrome" }
function Install-Firefox { Install-App -AppId "Mozilla.Firefox" -AppName "Mozilla Firefox" }
function Install-Brave { Install-App -AppId "Brave.Brave" -AppName "Brave Browser" }

# Game Launchers
function Install-Steam { Install-App -AppId "Valve.Steam" -AppName "Steam" }
function Install-Epic { Install-App -AppId "EpicGames.EpicGamesLauncher" -AppName "Epic Games Launcher" }
function Install-EA { Install-App -AppId "ElectronicArts.EADesktop" -AppName "EA App" }
function Install-Ubisoft { Install-App -AppId "Ubisoft.Connect" -AppName "Ubisoft Connect" }

# Security / Privacy Apps
function Install-ProtonAuthenticator { Install-App -AppId "Proton.ProtonAuthenticator" -AppName "Proton Authenticator" }
function Install-Portmaster { Install-App -AppId "Safing.Portmaster" -AppName "Portmaster" }
function Install-ProtonDrive { Install-App -AppId "Proton.ProtonDrive" -AppName "Proton Drive" }
function Install-ProtonMail { Install-App -AppId "Proton.ProtonMail" -AppName "Proton Mail" }
function Install-ProtonMailBridge { Install-App -AppId "Proton.ProtonMailBridge" -AppName "Proton Mail Bridge" }
function Install-ProtonPass { Install-App -AppId "Proton.ProtonPass" -AppName "Proton Pass" }
function Install-ProtonVPN { Install-App -AppId "Proton.ProtonVPN" -AppName "Proton VPN" }

function Install-Bitdefender { Install-App -AppId "Bitdefender.Bitdefender" -AppName "Bitdefender" }
function Install-BitdefenderVPN { Install-App -AppId "Bitdefender.BitdefenderVPN" -AppName "Bitdefender VPN" }
function Install-Mysterium { Install-App -AppId "Mysterium.Network" -AppName "Mysterium VPN" }
<#
# =========================
# Example Usage
# =========================
# Install-Chrome
# Install-Firefox
# Install-Steam


# =========================
# Prompt to Install an App
# =========================
$choice = Read-Host "Enter the app name to install (e.g., Chrome, Steam, ProtonVPN)"

switch ($choice.ToLower()) {
    "chrome"         { Install-Chrome }
    "portmaster"     { Install-Portmaster }
    "firefox"        { Install-Firefox }
    "brave"          { Install-Brave }
    "steam"          { Install-Steam }
    "epic"           { Install-Epic }
    "ea"             { Install-EA }
    "ubisoft"        { Install-Ubisoft }
    "protonauthenticator" { Install-ProtonAuthenticator }
    "protondrive"    { Install-ProtonDrive }
    "protonmail"     { Install-ProtonMail }
    "protonmailbridge" { Install-ProtonMailBridge }
    "protonpass"     { Install-ProtonPass }
    "protonvpn"      { Install-ProtonVPN }
    "bitdefender"    { Install-Bitdefender }
    "bitdefendervpn" { Install-BitdefenderVPN }
    "mysterium"      { Install-Mysterium }
    default {
        Write-Host "[ERROR] Unknown app name: $choice"
    }
}
#>