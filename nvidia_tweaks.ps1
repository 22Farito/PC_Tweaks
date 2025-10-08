# ----------------------------
# Locate NVIDIA Profile Inspector
# ----------------------------
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$BaseDir = Resolve-Path (Join-Path $ScriptDir "..\..")
$ProfileInspectorPath = Join-Path $BaseDir "Tools\nvidiaProfileInspector\NVIDIAProfileInspector.exe"

if (-not (Test-Path $ProfileInspectorPath)) {
    Write-Host "⚠️ NVIDIAProfileInspector.exe not found at $ProfileInspectorPath"
} else {
    Write-Host "✅ Found NVIDIAProfileInspector.exe at $ProfileInspectorPath"
}

# ----------------------------
# 3D Control Panel Tweaks via Profile Inspector (Silent, one invocation)
# ----------------------------
function Invoke-3DTweaks {
    if (-not (Test-Path $ProfileInspectorPath)) {
        Write-Host "⚠️ NVIDIAProfileInspector.exe not found at $ProfileInspectorPath"
        return
    }

    # List of (profile_name, setting_id, value)
    $settings = @(
        # Sync and Refresh
        @{ Profile="Sync and Refresh"; SettingID="0x0002"; Value="1" }  # V-Sync Off
        @{ Profile="Sync and Refresh"; SettingID="0x0004"; Value="1" }  # Triple Buffering On
        @{ Profile="Sync and Refresh"; SettingID="0x0008"; Value="1" }  # Fast Sync On

        # Anti-Aliasing
        @{ Profile="Anti-Aliasing"; SettingID="0x0002"; Value="1" }     # Anti-Aliasing Mode: Override
        @{ Profile="Anti-Aliasing"; SettingID="0x0004"; Value="2" }     # Anti-Aliasing Setting: 4x Multisampling
        @{ Profile="Anti-Aliasing"; SettingID="0x0008"; Value="1" }     # Transparency Anti-Aliasing: 2x Sparse Grid Supersampling

        # Texture Filtering
        @{ Profile="Texture Filtering"; SettingID="0x0002"; Value="1" } # Anisotropic Filtering: 16x
        @{ Profile="Texture Filtering"; SettingID="0x0004"; Value="0" } # Texture Filtering Quality: High Performance
        @{ Profile="Texture Filtering"; SettingID="0x0008"; Value="1" } # Texture Filtering Trilinear Optimization: On
        @{ Profile="Texture Filtering"; SettingID="0x0010"; Value="1" } # Texture Filtering Anisotropic Sample Optimization: On

        # Power Management
        @{ Profile="Power Management"; SettingID="0x0002"; Value="1" }  # Power Management Mode: Prefer Maximum Performance

        # Other Settings
        @{ Profile="Other"; SettingID="0x0001"; Value="1" }             # Shader Cache: On
        @{ Profile="Other"; SettingID="0x0002"; Value="1" }             # Low Latency Mode: Ultra
        @{ Profile="Other"; SettingID="0x0004"; Value="1" }             # Threaded Optimization: On
    )

    $profileArgs = $settings | ForEach-Object {
        "/SetSetting $($_.Profile):$($_.SettingID):$($_.Value)"
    }
    $cmd = "`"$ProfileInspectorPath`" $($profileArgs -join ' ')"

    try {
        Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile -WindowStyle Hidden -Command $cmd" -WindowStyle Hidden -Wait
        Write-Host "✅ All 3D settings applied in a single Profile Inspector invocation"
    } catch {
        Write-Host "⚠️ Failed to set 3D settings: $_"
    }
}

# ----------------------------
# Refresh Rate (user32.dll, all monitors)
# ----------------------------
Add-Type -AssemblyName System.Windows.Forms

# Only add the type if it doesn't already exist (avoids Add-Type errors)
if (-not ("DEVMODE" -as [type])) {
    Add-Type @"
using System;
using System.Runtime.InteropServices;
[StructLayout(LayoutKind.Sequential, CharSet = CharSet.Ansi)]
public struct DEVMODE {
    [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)]
    public string dmDeviceName;
    public short dmSpecVersion;
    public short dmDriverVersion;
    public short dmSize;
    public short dmDriverExtra;
    public int dmFields;
    public int dmPositionX;
    public int dmPositionY;
    public int dmDisplayOrientation;
    public int dmDisplayFixedOutput;
    public short dmColor;
    public short dmDuplex;
    public short dmYResolution;
    public short dmTTOption;
    public short dmCollate;
    [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)]
    public string dmFormName;
    public short dmLogPixels;
    public int dmBitsPerPel;
    public int dmPelsWidth;
    public int dmPelsHeight;
    public int dmDisplayFlags;
    public int dmDisplayFrequency;
    public int dmICMMethod;
    public int dmICMIntent;
    public int dmMediaType;
    public int dmDitherType;
    public int dmReserved1;
    public int dmReserved2;
    public int dmPanningWidth;
    public int dmPanningHeight;
}
public class NativeMethods {
    [DllImport("user32.dll", CharSet = CharSet.Ansi)]
    public static extern bool EnumDisplaySettings(string deviceName, int modeNum, ref DEVMODE devMode);
    [DllImport("user32.dll", CharSet = CharSet.Ansi)]
    public static extern int ChangeDisplaySettingsEx(string deviceName, ref DEVMODE devMode, IntPtr hwnd, uint dwflags, IntPtr lParam);
}
"@ -ErrorAction SilentlyContinue
}

function Get-MonitorRefreshRates {
    $monitors = [System.Windows.Forms.Screen]::AllScreens
    $results = @()

    foreach ($mon in $monitors) {
        $device = $mon.DeviceName
        $modes = @()
        $i = 0
        $devmode = New-Object DEVMODE
        # ✅ Fix: use the instance type instead of [DEVMODE]
        $devmode.dmSize = [System.Runtime.InteropServices.Marshal]::SizeOf($devmode.GetType())
        
        while ([NativeMethods]::EnumDisplaySettings($device, $i, [ref]$devmode)) {
            $modes += [PSCustomObject]@{
                Width      = $devmode.dmPelsWidth
                Height     = $devmode.dmPelsHeight
                BitsPerPel = $devmode.dmBitsPerPel
                Frequency  = $devmode.dmDisplayFrequency
            }
            $i++
        }

        $current = $modes | Where-Object {
            $_.Width -eq $mon.Bounds.Width -and $_.Height -eq $mon.Bounds.Height
        } | Sort-Object Frequency -Descending | Select-Object -First 1

        $rates = $modes | Where-Object {
            $_.Width -eq $mon.Bounds.Width -and $_.Height -eq $mon.Bounds.Height
        } | Select-Object -ExpandProperty Frequency -Unique | Sort-Object -Descending

        $results += [PSCustomObject]@{
            Monitor        = $device
            CurrentRefresh = $current.Frequency
            SupportedRates = $rates
            Resolution     = "$($mon.Bounds.Width)x$($mon.Bounds.Height)"
        }
    }
    return $results
}

function Set-MonitorMaxRefreshRate {
    $monitors = Get-MonitorRefreshRates
    foreach ($mon in $monitors) {
        Write-Host "Monitor: $($mon.Monitor) [$($mon.Resolution)]"
        Write-Host "  Supported refresh rates: $($mon.SupportedRates -join ', ') Hz"
        Write-Host "  Current refresh rate: $($mon.CurrentRefresh) Hz"
        if ($mon.SupportedRates.Count -gt 0 -and $mon.CurrentRefresh -lt $mon.SupportedRates[0]) {
            $max = $mon.SupportedRates[0]
            $devmode = New-Object DEVMODE
            $devmode.dmSize = [System.Runtime.InteropServices.Marshal]::SizeOf($devmode.GetType())
            [void][NativeMethods]::EnumDisplaySettings($mon.Monitor, -1, [ref]$devmode)
            $devmode.dmDisplayFrequency = $max
            $devmode.dmFields = 0x400000   # DM_DISPLAYFREQUENCY
            $result = [NativeMethods]::ChangeDisplaySettingsEx($mon.Monitor, [ref]$devmode, [IntPtr]::Zero, 0, [IntPtr]::Zero)
            if ($result -eq 0) {
                Write-Host "  ✅ Changed refresh rate to $max Hz"
            } else {
                Write-Host "  ⚠️ Failed to change refresh rate (code $result)"
            }
        } else {
            Write-Host "  ℹ️ Already using maximum refresh rate"
        }
    }
}


# ----------------------------
# Monitor Brightness/Contrast (Stub)
# ----------------------------
function Set-MonitorContrastBrightness {
    Write-Host "⚠️ Monitor DDC/CI brightness/contrast not supported natively in PowerShell."
    Write-Host "   Use third-party tools like ClickMonitorDDC or Monitorian for scripting."
}

# ----------------------------
# Main
# ----------------------------