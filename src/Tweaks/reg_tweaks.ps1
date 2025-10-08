# =================================================================================
#                                   REG TWEAKS
# =================================================================================

function Set-RegistryValue {
    param (
        [string]$Root,
        [string]$Path,
        [string]$Name,
        [Object]$Value,
        [Microsoft.Win32.RegistryValueKind]$ValueType = [Microsoft.Win32.RegistryValueKind]::DWord
    )
    try {
        $key = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey($Path, $true)
        if (-not $key) {
            $key = [Microsoft.Win32.Registry]::LocalMachine.CreateSubKey($Path)
        }
        $key.SetValue($Name, $Value, $ValueType)
        $key.Close()
        Write-Host "[SUCCESS] Set '$Root\$Path\$Name' = $Value"
        return $true
    }
    catch {
        Write-Host "[ERROR] Failed to set '$Root\$Path\$Name': $_"
        return $false
    }
}

# =========================
# Individual Tweaks
# =========================

function Win32_Priority {
    return Set-RegistryValue -Root "HKEY_LOCAL_MACHINE" `
                             -Path "SYSTEM\CurrentControlSet\Control\PriorityControl" `
                             -Name "Win32PrioritySeparation" `
                             -Value 38
}

function Network_Throttling {
    return Set-RegistryValue -Root "HKEY_LOCAL_MACHINE" `
                             -Path "SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" `
                             -Name "NetworkThrottlingIndex" `
                             -Value 0xFFFFFFFF
}

function Enable_GameMode {
    return Set-RegistryValue -Root "HKEY_CURRENT_USER" `
                             -Path "Software\Microsoft\GameBar" `
                             -Name "AllowAutoGameMode" `
                             -Value 1
}

function Enable_GPUHardwareScheduling {
    return Set-RegistryValue -Root "HKEY_LOCAL_MACHINE" `
                             -Path "SYSTEM\CurrentControlSet\Control\GraphicsDrivers" `
                             -Name "HwSchMode" `
                             -Value 2
}

function Games_Tweaks {
    $basePath = "SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games"
    $results = @()
    $results += Set-RegistryValue -Root "HKEY_LOCAL_MACHINE" -Path $basePath -Name "GPU Priority" -Value 8
    $results += Set-RegistryValue -Root "HKEY_LOCAL_MACHINE" -Path $basePath -Name "Priority" -Value 6
$results += Set-RegistryValue -Root "HKEY_LOCAL_MACHINE" -Path $basePath -Name "Scheduling Category" -Value "High" -ValueType ([Microsoft.Win32.RegistryValueKind]::String)
$results += Set-RegistryValue -Root "HKEY_LOCAL_MACHINE" -Path $basePath -Name "SFIO Priority" -Value "High" -ValueType ([Microsoft.Win32.RegistryValueKind]::String)
    return ($results -notcontains $false)
}

function GameBar_Tweaks {
    $basePath = "Software\Microsoft\GameBar"
    $results = @()
    $results += Set-RegistryValue -Root "HKEY_CURRENT_USER" -Path $basePath -Name "ShowStartupPanel" -Value 0
    $results += Set-RegistryValue -Root "HKEY_CURRENT_USER" -Path $basePath -Name "AllowGameDVR" -Value 0
    $results += Set-RegistryValue -Root "HKEY_CURRENT_USER" -Path $basePath -Name "AllowAutoGameMode" -Value 0
    $results += Set-RegistryValue -Root "HKEY_CURRENT_USER" -Path $basePath -Name "BroadcastingEnabled" -Value 0
    $results += Set-RegistryValue -Root "HKEY_CURRENT_USER" -Path $basePath -Name "ShowGameBarWhenGaming" -Value 0
    return ($results -notcontains $false)
}

function Set_TcpAckFrequency {
    param (
        [int]$Value = 1
    )

    $tcpipPath = "SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces"
    try {
        $interfaces = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey($tcpipPath).GetSubKeyNames()
        $success = $true

        foreach ($iface in $interfaces) {
            try {
                $subKey = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey("$tcpipPath\$iface", $true)
                $subKey.SetValue("TcpAckFrequency", $Value, [Microsoft.Win32.RegistryValueKind]::DWord)
                $subKey.Close()
                Write-Host "[SUCCESS] TcpAckFrequency set to $Value for adapter $iface"
            }
            catch {
                Write-Host "[ERROR] Failed to set TcpAckFrequency for adapter $iface"
                $success = $false
            }
        }
        return $success
    }
    catch {
        Write-Host "[ERROR] Failed to enumerate network adapters: $_"
        return $false
    }
}

# =========================
# Run All Tweaks Function
# =========================
function Invoke-AllTweaks {
    Write-Host "=== Running All Registry Tweaks ==="
    Win32_Priority
    Network_Throttling
    Enable_GameMode
    Enable_GPUHardwareScheduling
    Games_Tweaks
    GameBar_Tweaks
    Set_TcpAckFrequency -Value 1
    Write-Host "=== All Tweaks Completed ==="
}
