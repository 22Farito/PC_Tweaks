# ===============================
# Mouse Acceleration Toggle Logic
# ===============================

try {
    $mouseSettings = Get-ItemProperty -Path "HKCU:\Control Panel\Mouse"
    $isAccel = ($mouseSettings.MouseEnhancePointerPrecision -eq "1")
    $ChkMouseAcceleration.IsChecked = $isAccel
} catch {
    $ChkMouseAcceleration.IsChecked = $false
}

function Send-SettingChange {
    Add-Type @"
using System;
using System.Runtime.InteropServices;
public class Win32 {
    [DllImport("user32.dll", SetLastError=true, CharSet=CharSet.Auto)]
    public static extern IntPtr SendMessageTimeout(IntPtr hWnd, uint Msg, UIntPtr wParam, string lParam, uint fuFlags, uint uTimeout, out UIntPtr lpdwResult);
}
"@
    $HWND_BROADCAST = [intptr]0xFFFF
    $WM_SETTINGCHANGE = 0x001A
    $result = [uintptr]::Zero
    [Win32]::SendMessageTimeout($HWND_BROADCAST, $WM_SETTINGCHANGE, [uintptr]::Zero, "Control Panel\\Mouse", 2, 5000, [ref]$result) | Out-Null
}

$ChkMouseAcceleration.Add_Checked({
    try {
        Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name MouseEnhancePointerPrecision -Value "1"
        Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name MouseSpeed -Value "1"
        Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name MouseThreshold1 -Value "6"
        Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name MouseThreshold2 -Value "10"
        Send-SettingChange
        Write-Host "Mouse Acceleration / Enhance pointer precision ENABLED." -ForegroundColor Green
        Write-Log "Mouse Acceleration ENABLED"
        [System.Windows.MessageBox]::Show("Mouse Acceleration / Enhance pointer precision ENABLED. You may need to log off/on or reopen Mouse Properties for changes to show.")
    } catch {
        Write-Host "Failed to ENABLE Mouse Acceleration / Enhance pointer precision: $_" -ForegroundColor Red
        Write-Log "FAILED to enable Mouse Acceleration: $_"
        [System.Windows.MessageBox]::Show("FAILED to enable Mouse Acceleration / Enhance pointer precision.")
    }
})

$ChkMouseAcceleration.Add_Unchecked({
    try {
        Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name MouseEnhancePointerPrecision -Value "0"
        Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name MouseSpeed -Value "0"
        Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name MouseThreshold1 -Value "0"
        Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name MouseThreshold2 -Value "0"
        Send-SettingChange
        Write-Host "Mouse Acceleration / Enhance pointer precision DISABLED." -ForegroundColor Yellow
        Write-Log "Mouse Acceleration DISABLED"
        [System.Windows.MessageBox]::Show("Mouse Acceleration / Enhance pointer precision DISABLED. You may need to log off/on or reopen Mouse Properties for changes to show.")
    } catch {
        Write-Host "Failed to DISABLE Mouse Acceleration / Enhance pointer precision: $_" -ForegroundColor Red
        Write-Log "FAILED to disable Mouse Acceleration: $_"
        [System.Windows.MessageBox]::Show("FAILED to disable Mouse Acceleration / Enhance pointer precision.")
    }
})