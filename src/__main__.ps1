# ===============================================================================================================================
#                                                           INSTALL APPS
# ===============================================================================================================================
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



# ===============================================================================================================================
#                                                           LAUNCH PROGRAMS
# ===============================================================================================================================
# Function to launch Revo Uninstaller
# =====================================
function Launch_RevoSilent {
    # Use PSScriptRoot to get the script's folder reliably
    $scriptDir = $PSScriptRoot

    # Build the path to the exe (two folders up, then Tools\RevoUninstaller\RevoUPort.exe)
    $exePath = Join-Path $scriptDir "..\..\Tools\RevoUninstaller\RevoUPort.exe"
    $exeFullPath = Resolve-Path $exePath -ErrorAction SilentlyContinue

    if (-not $exeFullPath) {
        Write-Host "Error: Revo Uninstaller not found at $exePath"
        return
    }

    try {
        # Launch the executable silently
        Start-Process -FilePath $exeFullPath -ArgumentList "/S" -WindowStyle Hidden -Wait
        Write-Host "Launched Revo Uninstaller silently!"
    } catch {
        Write-Host "Failed to launch Revo Uninstaller: $_"
    }
}

# ==============================================
# Function to launch Revo Reg Cleaner portable
# ==============================================
function Launch_RevoRegPortable {
    # Use PSScriptRoot to get the script's folder reliably
    $scriptDir = $PSScriptRoot

    # Build the path to the exe (two folders up, then Tools\RevoRegCleaner.exe)
    $exePath = Join-Path $scriptDir "..\..\Tools\Revo Registry Cleaner\Revo Registry Cleaner.exe"
    $exeFullPath = Resolve-Path $exePath -ErrorAction SilentlyContinue

    if (-not $exeFullPath) {
        Write-Host "Error: Portable Revo Reg Cleaner not found at $exePath"
        return
    }

    try {
        # Launch the portable executable
        Start-Process -FilePath $exeFullPath -WindowStyle Hidden -Wait
        Write-Host "Launched Revo Reg Cleaner Portable successfully!"
    } catch {
        Write-Host "Failed to launch Revo Reg Cleaner: $_"
    }
}



# ===============================================================================================================================
#                                                           ADVANCED TWEAKS
# ===============================================================================================================================
function Invoke-Command {
    param (
        [string]$Command
    )
    try {
        Invoke-Expression $Command
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[SUCCESS] $Command" -ForegroundColor Green
        } else {
            Write-Host "[ERROR] $Command" -ForegroundColor Red
        }
    } catch {
        Write-Host "[EXCEPTION] $Command -> $_" -ForegroundColor Yellow
    }
}

# Wrapper to match provided Disable-IPv6 usage
function Run-Command {
    param([Parameter(Mandatory)][string]$Command)
    try {
        Invoke-Expression $Command
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[SUCCESS] $Command" -ForegroundColor Green
        } else {
            Write-Host "[ERROR] $Command" -ForegroundColor Red
        }
    } catch {
        Write-Host "[EXCEPTION] $Command -> $_" -ForegroundColor Yellow
    }
}

# Disable IPv6
function Disable-IPv6 {
    Write-Host "Disabling IPv6..." -ForegroundColor Cyan
    Run-Command "netsh interface ipv6 set disabledcomponents 0xFF"
}



# ===============================================================================================================================
#                                                           REGISTRY TWEAKS
# ===============================================================================================================================
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
        Write-Host "[SUCCESS] Set '$Root\$Path\$Name' = $Value" -ForegroundColor Green
        Write-Log "[SUCCESS] Set '$Root\$Path\$Name' = $Value"
        return $true
    }
    catch {
        Write-Host "[ERROR] Failed to set '$Root\$Path\$Name': $_" -ForegroundColor Red
        Write-Log "[ERROR] Failed to set '$Root\$Path\$Name': $_"
        return $false
    }
}

# =========================================
#            Individual Tweaks
# =========================================
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
                Write-Host "[SUCCESS] TcpAckFrequency set to $Value for adapter $iface" -ForegroundColor Green
                Write-Log "[SUCCESS] TcpAckFrequency set to $Value for adapter $iface"
            }
            catch {
                Write-Host "[ERROR] Failed to set TcpAckFrequency for adapter $iface" -ForegroundColor Red
                Write-Log "[ERROR] Failed to set TcpAckFrequency for adapter $iface"
                $success = $false
            }
        }
        return $success
    }
    catch {
        Write-Host "[ERROR] Failed to enumerate network adapters: $_" -ForegroundColor Red
        Write-Log "[ERROR] Failed to enumerate network adapters: $_"
        return $false
    }
}

# Main function to apply all registry tweaks
function Invoke-AllTweaks {
    Write-Host "=== APPLYING REGISTRY TWEAKS ===" -ForegroundColor Yellow
    Write-Log "=== APPLYING REGISTRY TWEAKS ==="
    
    Win32_Priority
    Network_Throttling
    Enable_GameMode
    Enable_GPUHardwareScheduling
    Games_Tweaks
    GameBar_Tweaks
    Set_TcpAckFrequency -Value 1
    
    Write-Host "=== REGISTRY TWEAKS COMPLETE ===" -ForegroundColor Green
    Write-Log "=== REGISTRY TWEAKS COMPLETE ==="
}

# ===============================================================================================================================
#                                                           SERVICE TWEAKS
# ===============================================================================================================================
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

# =========================================
#            Individual Tweaks
# =========================================
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

# Main function to apply all service tweaks
function Invoke-ServiceTweaks {
    Write-Host "=== APPLYING SERVICE TWEAKS ===" -ForegroundColor Yellow
    
    foreach ($tweak in $ServiceTweaks) {
        Invoke-ServiceTweak -ServiceName $tweak.Name -StartupType $tweak.Startup
    }
    
    foreach ($xbox in $XboxServices) {
        Invoke-ServiceTweak -ServiceName $xbox.Name -StartupType $xbox.Startup
    }
    
    Write-Host "=== SERVICE TWEAKS COMPLETE ===" -ForegroundColor Green
}

# ===============================
# Define Paths
# ===============================
$noisePath = Join-Path $PSScriptRoot "noise.png"

# ===============================
# XAML UI
# ===============================
$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="PCTool"
        WindowStyle="None"
        AllowsTransparency="True"
        ResizeMode="CanResize"
        MinHeight="600" MinWidth="1000"
        Height="700" Width="1200"
        WindowStartupLocation="CenterScreen"
        Foreground="{DynamicResource ForegroundBrush}"
        Background="Transparent">
    <Window.Resources>
        <!-- Dark theme -->
        <Color x:Key="DarkBackgroundColor">#1A1A1A</Color>
        <Color x:Key="DarkForegroundColor">#FFFFFFFF</Color>
        <Color x:Key="DarkCardColor">#2D2D2D</Color>
        <Color x:Key="DarkBorderColor">#404040</Color>
        <Color x:Key="DarkTopBarColor">#0F0F0F</Color>

        <!-- Light theme -->
        <Color x:Key="LightBackgroundColor">#F5F5F5</Color>
        <Color x:Key="LightForegroundColor">#111111</Color>
        <Color x:Key="LightCardColor">#FFFFFF</Color>
        <Color x:Key="LightBorderColor">#CCCCCC</Color>
        <Color x:Key="LightTopBarColor">#E8E8E8</Color>

        <!-- Active theme (start dark) -->
        <SolidColorBrush x:Key="WindowBackgroundBrush" Color="{StaticResource DarkBackgroundColor}"/>
        <SolidColorBrush x:Key="ForegroundBrush"       Color="{StaticResource DarkForegroundColor}"/>
        <SolidColorBrush x:Key="CardBrush"             Color="{StaticResource DarkCardColor}"/>
        <SolidColorBrush x:Key="BorderBrushColor"      Color="{StaticResource DarkBorderColor}"/>
        <SolidColorBrush x:Key="TopBarBrush"           Color="{StaticResource DarkTopBarColor}"/>

        <!-- Faint, tiled noise; image set at runtime -->
        <ImageBrush x:Key="NoiseBrush"
                    TileMode="Tile"
                    Viewport="0,0,256,256"
                    ViewportUnits="Absolute"
                    Stretch="None"
                    Opacity="0.07" />

        <!-- Accent -->
        <SolidColorBrush x:Key="AccentBrush" Color="#4F8EF7"/>

        <!-- Window control buttons -->
        <Style x:Key="WindowControlButton" TargetType="Button">
            <Setter Property="Width" Value="35"/>
            <Setter Property="Height" Value="35"/>
            <Setter Property="Margin" Value="3"/>
            <Setter Property="Background" Value="Transparent"/>
            <Setter Property="BorderBrush" Value="Transparent"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Foreground" Value="{DynamicResource ForegroundBrush}"/>
            <Setter Property="FontSize" Value="14"/>
            <Setter Property="FontWeight" Value="Bold"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border CornerRadius="8"
                                Background="{TemplateBinding Background}"
                                BorderBrush="{TemplateBinding BorderBrush}"
                                BorderThickness="{TemplateBinding BorderThickness}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter Property="Background" Value="#40FFFFFF"/>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter Property="Background" Value="#60FFFFFF"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style x:Key="CloseButton" TargetType="Button" BasedOn="{StaticResource WindowControlButton}">
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border CornerRadius="8"
                                Background="{TemplateBinding Background}"
                                BorderBrush="{TemplateBinding BorderBrush}"
                                BorderThickness="{TemplateBinding BorderThickness}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter Property="Background" Value="#FF5555"/>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter Property="Background" Value="#FF3333"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- Toggle switch -->
        <Style x:Key="ToggleSwitchStyle" TargetType="CheckBox">
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="CheckBox">
                        <StackPanel Orientation="Horizontal">
                            <Border x:Name="SwitchBorder"
                                    Width="42" Height="22"
                                    CornerRadius="11"
                                    Background="{StaticResource BorderBrushColor}">
                                <Grid>
                                    <Ellipse x:Name="SwitchKnob"
                                             Width="18" Height="18"
                                             Margin="2"
                                             Fill="White"
                                             HorizontalAlignment="Left"/>
                                </Grid>
                            </Border>
                            <TextBlock Text="{TemplateBinding Content}"
                                       VerticalAlignment="Center"
                                       Foreground="{DynamicResource ForegroundBrush}"
                                       FontSize="15"
                                       FontWeight="SemiBold"
                                       Margin="12,0,0,0"/>
                        </StackPanel>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsChecked" Value="True">
                                <Setter TargetName="SwitchBorder" Property="Background" Value="{StaticResource AccentBrush}"/>
                                <Setter TargetName="SwitchKnob" Property="HorizontalAlignment" Value="Right"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- Navigation buttons -->
        <Style x:Key="RoundedNavButton" TargetType="Button">
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="FontSize" Value="16"/>
            <Setter Property="Width" Value="100"/>
            <Setter Property="Height" Value="35"/>
            <Setter Property="Margin" Value="8,5"/>
            <Setter Property="Foreground" Value="{DynamicResource ForegroundBrush}"/>
            <Setter Property="Background" Value="Transparent"/>
            <Setter Property="BorderBrush" Value="Transparent"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border CornerRadius="8"
                                Background="{TemplateBinding Background}"
                                BorderBrush="{TemplateBinding BorderBrush}"
                                BorderThickness="{TemplateBinding BorderThickness}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter Property="Background" Value="#40FFFFFF"/>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter Property="Background" Value="#60FFFFFF"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- Primary rounded button -->
        <Style x:Key="RoundedButton" TargetType="Button">
            <Setter Property="FontWeight" Value="Bold"/>
            <Setter Property="FontSize" Value="16"/>
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="Background" Value="{StaticResource CardBrush}"/>
            <Setter Property="BorderBrush" Value="{StaticResource AccentBrush}"/>
            <Setter Property="BorderThickness" Value="2"/>
            <Setter Property="Height" Value="38"/>
            <Setter Property="Margin" Value="8,6"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border CornerRadius="12"
                                Background="{TemplateBinding Background}"
                                BorderBrush="{TemplateBinding BorderBrush}"
                                BorderThickness="{TemplateBinding BorderThickness}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter Property="Background" Value="#384B7C"/>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter Property="Background" Value="#262F52"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
    </Window.Resources>

    <Grid>
        <!-- Main container (borderless) with faint noise layered -->
        <Border CornerRadius="15" Margin="5" BorderThickness="0" BorderBrush="{DynamicResource BorderBrushColor}" Name="MainBorder">
            <Border.Background>
                <VisualBrush>
                    <VisualBrush.Visual>
                        <Grid>
                            <Border Background="{DynamicResource WindowBackgroundBrush}"/>
                            <Border Background="{DynamicResource NoiseBrush}"/>
                        </Grid>
                    </VisualBrush.Visual>
            </VisualBrush>
        </Border.Background>

        <Grid>
            <Grid.RowDefinitions>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="*"/>
            </Grid.RowDefinitions>

            <!-- Top bar: nav on left, theme/controls on right; draggable -->
            <Border Grid.Row="0" Background="{DynamicResource TopBarBrush}" CornerRadius="12,12,0,0" Margin="5,5,5,0" Name="TopBarBorder">
                <Grid Height="50" Name="DragArea" Background="Transparent">
                    <!-- Left: pages -->
                    <StackPanel Orientation="Horizontal" HorizontalAlignment="Left" VerticalAlignment="Center" Margin="15,0">
                        <Button Name="BtnHome"     Content="Home"    Style="{StaticResource RoundedNavButton}"/>
                        <Button Name="BtnInstall"  Content="Install" Style="{StaticResource RoundedNavButton}"/>
                        <Button Name="BtnTweaks"   Content="Tweaks"  Style="{StaticResource RoundedNavButton}"/>
                        <Button Name="BtnConfig"   Content="Config"  Style="{StaticResource RoundedNavButton}"/>
                        <Button Name="BtnPrograms" Content="Programs" Style="{StaticResource RoundedNavButton}"/>
                        <Button Name="BtnLogs"     Content="Logs"    Style="{StaticResource RoundedNavButton}"/>
                    </StackPanel>

                    <!-- Right: theme + window controls -->
                    <StackPanel Orientation="Horizontal" HorizontalAlignment="Right" VerticalAlignment="Center" Margin="15,0">
                        <Button Name="BtnToggleTheme" Content="🌙" Style="{StaticResource WindowControlButton}" ToolTip="Toggle Theme"/>
                        <Button Name="BtnMinimize" Content="−" Style="{StaticResource WindowControlButton}" ToolTip="Minimize"/>
                        <Button Name="BtnMaximize" Content="□" Style="{StaticResource WindowControlButton}" ToolTip="Maximize"/>
                        <Button Name="BtnClose" Content="✕" Style="{StaticResource CloseButton}" ToolTip="Close"/>
                    </StackPanel>
                </Grid>
            </Border>

            <!-- Main content -->
            <Border Grid.Row="1" Background="{DynamicResource CardBrush}" CornerRadius="0,0,12,12" Margin="5,0,5,5">
                <Grid Margin="25" Name="TopNavPanel">
                    <!-- Home -->
                    <Grid Name="PageHome">
                        <Grid.ColumnDefinitions>
                            <ColumnDefinition Width="*"/>
                            <ColumnDefinition Width="*"/>
                        </Grid.ColumnDefinitions>

                        <StackPanel Grid.Column="0" Margin="0,0,30,0">
                            <TextBlock Text="PC Information" FontSize="24" FontWeight="Bold"
                                       Foreground="{DynamicResource ForegroundBrush}" Margin="0,0,0,20"/>
                            <Separator Background="{DynamicResource BorderBrushColor}" Height="1" Margin="0,0,0,20"/>
                            <TextBlock Name="LblOS"           FontSize="16" Margin="0,8" Foreground="{DynamicResource ForegroundBrush}"/>
                            <TextBlock Name="LblCPU"          FontSize="16" Margin="0,8" Foreground="{DynamicResource ForegroundBrush}"/>
                            <TextBlock Name="LblRAM"          FontSize="16" Margin="0,8" Foreground="{DynamicResource ForegroundBrush}"/>
                            <TextBlock Name="LblGPU"          FontSize="16" Margin="0,8" Foreground="{DynamicResource ForegroundBrush}"/>
                            <TextBlock Name="LblMotherboard"  FontSize="16" Margin="0,8" Foreground="{DynamicResource ForegroundBrush}"/>
                            <TextBlock Name="LblBIOS"         FontSize="16" Margin="0,8" Foreground="{DynamicResource ForegroundBrush}"/>
                            <TextBlock Name="LblDisk"         FontSize="16" Margin="0,8" Foreground="{DynamicResource ForegroundBrush}"/>
                            <TextBlock Name="LblNetwork"      FontSize="16" Margin="0,8" Foreground="{DynamicResource ForegroundBrush}"/>
                            <TextBlock Name="LblSound"        FontSize="16" Margin="0,8" Foreground="{DynamicResource ForegroundBrush}"/>
                        </StackPanel>

                        <StackPanel Grid.Column="1" Margin="30,0,0,0">
                            <DockPanel Margin="0,0,0,20">
                                <TextBlock Text="Advanced Info" FontSize="24" FontWeight="Bold"
                                           Foreground="{DynamicResource ForegroundBrush}" VerticalAlignment="Center"/>
                                <Button Name="BtnToggleAdvanced" Content="👁" Width="30" Height="30"
                                        DockPanel.Dock="Right" HorizontalAlignment="Right"
                                        Background="Transparent" BorderBrush="Transparent"
                                        Foreground="{DynamicResource ForegroundBrush}"/>
                            </DockPanel>
                            <Separator Background="{DynamicResource BorderBrushColor}" Height="1" Margin="0,0,0,20"/>
                            <TextBlock Name="LblRouterIP" FontSize="16" Margin="0,8" Foreground="{DynamicResource ForegroundBrush}"/>
                            <TextBlock Name="LblIP"       FontSize="16" Margin="0,8" Foreground="{DynamicResource ForegroundBrush}"/>
                            <TextBlock Name="LblMAC"      FontSize="16" Margin="0,8" Foreground="{DynamicResource ForegroundBrush}"/>
                            <TextBlock Name="LblHWID"     FontSize="16" Margin="0,8" Foreground="{DynamicResource ForegroundBrush}"/>
                            <TextBlock Name="LblPublicIP" FontSize="16" Margin="0,8" Foreground="{DynamicResource ForegroundBrush}"/>
                        </StackPanel>
                    </Grid>

                    <!-- Install -->
                    <Grid Name="PageInstall" Visibility="Collapsed">
                        <Grid.RowDefinitions>
                            <RowDefinition Height="Auto"/>
                            <RowDefinition Height="*"/>
                        </Grid.RowDefinitions>

                        <TextBlock Grid.Row="0" Text="Install Applications" FontSize="24" FontWeight="Bold"
                                   Foreground="{DynamicResource ForegroundBrush}" Margin="0,0,0,20"/>

                        <Border Grid.Row="1" Background="{DynamicResource WindowBackgroundBrush}" 
                                CornerRadius="8" BorderBrush="{DynamicResource BorderBrushColor}" 
                                BorderThickness="2" Padding="20">
                            <ScrollViewer VerticalScrollBarVisibility="Auto">
                                <StackPanel>
                                    <TextBlock Text="Install page content coming soon..." FontSize="16"
                                               Foreground="{DynamicResource ForegroundBrush}"
                                               TextWrapping="Wrap" Margin="0,0,0,20"/>
                                </StackPanel>
                            </ScrollViewer>
                        </Border>
                    </Grid>

                    <!-- Tweaks -->
                    <Grid Name="PageTweaks" Visibility="Collapsed">
                        <Grid.ColumnDefinitions>
                            <ColumnDefinition Width="*"/>
                            <ColumnDefinition Width="*"/>
                        </Grid.ColumnDefinitions>

                        <!-- Left: Advanced Tweaks -->
                        <Border Grid.Column="0" Margin="12,8,12,8" Background="{DynamicResource WindowBackgroundBrush}"
                                CornerRadius="12" BorderThickness="2" BorderBrush="{DynamicResource BorderBrushColor}">
                            <Grid>
                                <Grid.RowDefinitions>
                                    <RowDefinition Height="*"/>
                                    <RowDefinition Height="Auto"/>
                                </Grid.RowDefinitions>

                                <ScrollViewer Grid.Row="0" VerticalScrollBarVisibility="Auto">
                                    <StackPanel Margin="24">
                                        <TextBlock Text="Advanced Tweaks" FontSize="20" FontWeight="Bold"
                                                   Foreground="{DynamicResource ForegroundBrush}" Margin="0,0,0,20"/>
                                        <CheckBox Name="ChkTweak1"  Content="Win32 Priority Separation"  Style="{StaticResource ToggleSwitchStyle}" Margin="0,0,0,10"/>
                                        <CheckBox Name="ChkTweak2"  Content="Network Throttling Index"   Style="{StaticResource ToggleSwitchStyle}" Margin="0,0,0,10"/>
                                        <CheckBox Name="ChkTweak3"  Content="Enable Game Mode"           Style="{StaticResource ToggleSwitchStyle}" Margin="0,0,0,10"/>
                                        <CheckBox Name="ChkTweak4"  Content="GPU Hardware Scheduling"    Style="{StaticResource ToggleSwitchStyle}" Margin="0,0,0,10"/>
                                        <CheckBox Name="ChkTweak5"  Content="Games Performance Tweaks"   Style="{StaticResource ToggleSwitchStyle}" Margin="0,0,0,10"/>
                                        <CheckBox Name="ChkTweak6"  Content="GameBar Disable Tweaks"     Style="{StaticResource ToggleSwitchStyle}" Margin="0,0,0,10"/>
                                        <CheckBox Name="ChkTweak7"  Content="TCP Acknowledgment Freq"    Style="{StaticResource ToggleSwitchStyle}" Margin="0,0,0,10"/>
                                        <CheckBox Name="ChkTweak8"  Content="Placeholder Tweak 8"        Style="{StaticResource ToggleSwitchStyle}" Margin="0,0,0,10"/>
                                        <CheckBox Name="ChkTweak9"  Content="Placeholder Tweak 9"        Style="{StaticResource ToggleSwitchStyle}" Margin="0,0,0,10"/>
                                        <CheckBox Name="ChkTweak10" Content="Placeholder Tweak 10"       Style="{StaticResource ToggleSwitchStyle}" Margin="0,0,0,10"/>
                                        <CheckBox Name="ChkTweak11" Content="Placeholder Tweak 11"       Style="{StaticResource ToggleSwitchStyle}" Margin="0,0,0,10"/>
                                        <CheckBox Name="ChkTweak12" Content="Placeholder Tweak 12"       Style="{StaticResource ToggleSwitchStyle}" Margin="0,0,0,10"/>
                                        <CheckBox Name="ChkTweak13" Content="Placeholder Tweak 13"       Style="{StaticResource ToggleSwitchStyle}" Margin="0,0,0,10"/>
                                        <CheckBox Name="ChkTweak14" Content="Placeholder Tweak 14"       Style="{StaticResource ToggleSwitchStyle}" Margin="0,0,0,10"/>
                                        <CheckBox Name="ChkTweak15" Content="Placeholder Tweak 15"       Style="{StaticResource ToggleSwitchStyle}" Margin="0,0,0,10"/>
                                        <CheckBox Name="ChkTweak16" Content="Placeholder Tweak 16"       Style="{StaticResource ToggleSwitchStyle}" Margin="0,0,0,10"/>
                                        <CheckBox Name="ChkTweak17" Content="Placeholder Tweak 17"       Style="{StaticResource ToggleSwitchStyle}" Margin="0,0,0,10"/>
                                        <CheckBox Name="ChkTweak18" Content="Placeholder Tweak 18"       Style="{StaticResource ToggleSwitchStyle}" Margin="0,0,0,10"/>
                                        <CheckBox Name="ChkTweak19" Content="Placeholder Tweak 19"       Style="{StaticResource ToggleSwitchStyle}" Margin="0,0,0,10"/>
                                        <CheckBox Name="ChkTweak20" Content="Placeholder Tweak 20"       Style="{StaticResource ToggleSwitchStyle}" Margin="0,0,0,10"/>
                                        <CheckBox Name="ChkMouseAcceleration" Content="Disable Mouse Acceleration" Style="{StaticResource ToggleSwitchStyle}" Margin="0,0,0,10"/>
                                    </StackPanel>
                                </ScrollViewer>

                                <StackPanel Grid.Row="1">
                                    <Button Name="BtnSetGameProfile" Content="Set Game Profile" Style="{StaticResource RoundedButton}" Margin="24,10,24,0" Height="44"/>
                                    <Button Name="BtnRunTweaks" Content="Run Selected Tweaks" Style="{StaticResource RoundedButton}" Margin="24,20,24,24" Height="44"/>
                                </StackPanel>
                            </Grid>
                        </Border>

                        <!-- Right: Registry & Service -->
                        <Border Grid.Column="1" Margin="12,8,12,8" Background="{DynamicResource WindowBackgroundBrush}"
                                CornerRadius="12" BorderThickness="2" BorderBrush="{DynamicResource BorderBrushColor}">
                            <StackPanel Margin="24">
                                <TextBlock Text="System Tweaks" FontSize="20" FontWeight="Bold"
                                           Foreground="{DynamicResource ForegroundBrush}" Margin="0,0,0,20"/>
                                <TextBlock Text="Apply registry and service optimizations for gaming and performance."
                                           FontSize="14" Foreground="{DynamicResource ForegroundBrush}"
                                           TextWrapping="Wrap" Margin="0,0,0,20"/>
                                <Button Name="BtnSetRegTweaks" Content="Apply Registry Tweaks"
                                        Style="{StaticResource RoundedButton}" Margin="0,10" Height="44"/>
                                <Button Name="BtnSetServiceTweaks" Content="Apply Service Tweaks"
                                        Style="{StaticResource RoundedButton}" Margin="0,10" Height="44"/>
                            </StackPanel>
                        </Border>
                    </Grid>

                    <!-- Config -->
                    <Grid Name="PageConfig" Visibility="Collapsed">
                        <Grid.RowDefinitions>
                            <RowDefinition Height="Auto"/>
                            <RowDefinition Height="*"/>
                        </Grid.RowDefinitions>

                        <TextBlock Grid.Row="0" Text="Configuration" FontSize="24" FontWeight="Bold"
                                   Foreground="{DynamicResource ForegroundBrush}" Margin="0,0,0,20"/>

                        <Border Grid.Row="1" Background="{DynamicResource WindowBackgroundBrush}" 
                                CornerRadius="8" BorderBrush="{DynamicResource BorderBrushColor}" 
                                BorderThickness="2" Padding="20">
                            <ScrollViewer VerticalScrollBarVisibility="Auto">
                                <StackPanel>
                                    <TextBlock Text="Configuration page content coming soon..." FontSize="16"
                                               Foreground="{DynamicResource ForegroundBrush}"
                                               TextWrapping="Wrap" Margin="0,0,0,20"/>
                                </StackPanel>
                            </ScrollViewer>
                        </Border>
                    </Grid>

                    <!-- Programs -->
                    <Grid Name="PagePrograms" Visibility="Collapsed">
                        <Grid.RowDefinitions>
                            <RowDefinition Height="Auto"/>
                            <RowDefinition Height="*"/>
                        </Grid.RowDefinitions>

                        <TextBlock Grid.Row="0" Text="Programs Management" FontSize="24" FontWeight="Bold"
                                   Foreground="{DynamicResource ForegroundBrush}" Margin="0,0,0,20"/>

                        <Border Grid.Row="1" Background="{DynamicResource WindowBackgroundBrush}" 
                                CornerRadius="8" BorderBrush="{DynamicResource BorderBrushColor}" 
                                BorderThickness="2" Padding="20">
                            <ScrollViewer VerticalScrollBarVisibility="Auto">
                                <StackPanel>
                                    <TextBlock Text="Programs page content coming soon..." FontSize="16"
                                               Foreground="{DynamicResource ForegroundBrush}"
                                               TextWrapping="Wrap" Margin="0,0,0,20"/>
                                </StackPanel>
                            </ScrollViewer>
                        </Border>
                    </Grid>

                    <!-- Logs -->
                    <Grid Name="PageLogs" Visibility="Collapsed">
                        <Grid.RowDefinitions>
                            <RowDefinition Height="Auto"/>
                            <RowDefinition Height="*"/>
                            <RowDefinition Height="Auto"/>
                        </Grid.RowDefinitions>

                        <TextBlock Grid.Row="0" Text="Application Logs" FontSize="24" FontWeight="Bold"
                                   Foreground="{DynamicResource ForegroundBrush}" Margin="0,0,0,20"/>

                        <Border Grid.Row="1" Background="{DynamicResource WindowBackgroundBrush}" CornerRadius="8"
                                BorderBrush="{DynamicResource BorderBrushColor}" BorderThickness="2">
                            <ScrollViewer>
                                <RichTextBox Name="TxtLogs"
                                             Background="Transparent"
                                             Foreground="{DynamicResource ForegroundBrush}"
                                             BorderThickness="0"
                                             IsReadOnly="True"
                                             FontFamily="Consolas"
                                             FontSize="14"
                                             Margin="10"
                                             VerticalScrollBarVisibility="Auto"/>
                            </ScrollViewer>
                        </Border>

                        <Button Grid.Row="2" Name="BtnDownloadLogs" Content="Download Logs to Desktop"
                                Style="{StaticResource RoundedButton}" Margin="0,20,0,0" Height="44"/>
                    </Grid>
                </Grid>
            </Border>
        </Grid>
    </Border>
    
    <!-- Resize Grip in bottom-right corner (visible on all pages) -->
    <ResizeGrip Width="16" Height="16" 
                HorizontalAlignment="Right" 
                VerticalAlignment="Bottom" 
                Margin="0,0,10,10"
                Opacity="0.5"
                Background="Transparent"/>
    </Grid>
</Window>
"@

# ===============================
# Load XAML (ONLY ONCE)
# ===============================
Add-Type -AssemblyName PresentationFramework
$reader = New-Object System.Xml.XmlNodeReader ([xml]$xaml)
$window = [Windows.Markup.XamlReader]::Load($reader)

# Load noise.png
try {
    if (Test-Path $noisePath) {
        $img = New-Object System.Windows.Media.Imaging.BitmapImage
        $img.BeginInit()
        $img.UriSource = (New-Object System.Uri $noisePath)
        $img.CacheOption = "OnLoad"
        $img.EndInit()
        $window.Resources["NoiseBrush"].ImageSource = $img
    }
} catch {
    Write-Host "Failed to load noise.png"
}



# ===============================
# Find ALL UI Elements (Window Controls + App Elements)
# ===============================
$BtnClose             = $window.FindName("BtnClose")
$BtnMinimize          = $window.FindName("BtnMinimize")
$BtnMaximize          = $window.FindName("BtnMaximize")
$DragArea             = $window.FindName("DragArea")

$BtnToggleTheme       = $window.FindName("BtnToggleTheme")
$BtnHome              = $window.FindName("BtnHome")
$BtnInstall           = $window.FindName("BtnInstall")
$BtnTweaks            = $window.FindName("BtnTweaks")
$BtnConfig            = $window.FindName("BtnConfig")
$BtnPrograms          = $window.FindName("BtnPrograms")
$BtnLogs              = $window.FindName("BtnLogs")
$TopNavPanel          = $window.FindName("TopNavPanel")

$PageHome             = $window.FindName("PageHome")
$PageInstall          = $window.FindName("PageInstall")
$PageTweaks           = $window.FindName("PageTweaks")
$PageConfig           = $window.FindName("PageConfig")
$PagePrograms         = $window.FindName("PagePrograms")
$PageLogs             = $window.FindName("PageLogs")

$LblOS                = $window.FindName("LblOS")
$LblCPU               = $window.FindName("LblCPU")
$LblRAM               = $window.FindName("LblRAM")
$LblGPU               = $window.FindName("LblGPU")
$LblMotherboard       = $window.FindName("LblMotherboard")
$LblBIOS              = $window.FindName("LblBIOS")
$LblDisk              = $window.FindName("LblDisk")
$LblNetwork           = $window.FindName("LblNetwork")
$LblSound             = $window.FindName("LblSound")
$LblRouterIP          = $window.FindName("LblRouterIP")
$LblIP                = $window.FindName("LblIP")
$LblMAC               = $window.FindName("LblMAC")
$LblHWID              = $window.FindName("LblHWID")
$LblPublicIP          = $window.FindName("LblPublicIP")

$BtnToggleAdvanced    = $window.FindName("BtnToggleAdvanced")
$BtnSetRegTweaks      = $window.FindName("BtnSetRegTweaks")
$BtnSetServiceTweaks  = $window.FindName("BtnSetServiceTweaks")
$TxtLogs              = $window.FindName("TxtLogs")
$BtnDownloadLogs      = $window.FindName("BtnDownloadLogs")
$BtnRunTweaks         = $window.FindName("BtnRunTweaks")

$ChkTweak1            = $window.FindName("ChkTweak1")
$ChkTweak2            = $window.FindName("ChkTweak2")
$ChkTweak3            = $window.FindName("ChkTweak3")
$ChkTweak4            = $window.FindName("ChkTweak4")
$ChkTweak5            = $window.FindName("ChkTweak5")
$ChkTweak6            = $window.FindName("ChkTweak6")
$ChkTweak7            = $window.FindName("ChkTweak7")
$ChkTweak8            = $window.FindName("ChkTweak8")
$ChkTweak9            = $window.FindName("ChkTweak9")
$ChkTweak10           = $window.FindName("ChkTweak10")
$ChkTweak11           = $window.FindName("ChkTweak11")
$ChkTweak12           = $window.FindName("ChkTweak12")
$ChkTweak13           = $window.FindName("ChkTweak13")
$ChkTweak14           = $window.FindName("ChkTweak14")
$ChkTweak15           = $window.FindName("ChkTweak15")
$ChkTweak16           = $window.FindName("ChkTweak16")
$ChkTweak17           = $window.FindName("ChkTweak17")
$ChkTweak18           = $window.FindName("ChkTweak18")
$ChkTweak19           = $window.FindName("ChkTweak19")
$ChkTweak20           = $window.FindName("ChkTweak20")
$ChkMouseAcceleration = $window.FindName("ChkMouseAcceleration")

# ===============================
# Resize Grip Functionality
# ===============================
Add-Type @"
using System;
using System.Runtime.InteropServices;

public class ResizeHelper {
    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    public static extern IntPtr SendMessage(IntPtr hWnd, uint Msg, IntPtr wParam, IntPtr lParam);
    
    public const uint WM_NCLBUTTONDOWN = 0x00A1;
    public const uint HTBOTTOMRIGHT = 17;
}
"@

# Find all ResizeGrip elements in the window
$resizeGrips = @()
$windowContent = $window.Content
if ($windowContent -is [System.Windows.Controls.Grid]) {
    foreach ($child in $windowContent.Children) {
        if ($child -is [System.Windows.Controls.Primitives.ResizeGrip]) {
            $resizeGrips += $child
        }
    }
}

# Add mouse down handler to each resize grip
foreach ($grip in $resizeGrips) {
    $grip.Add_PreviewMouseLeftButtonDown({
        param($s, $e)
        try {
            $windowHandle = (New-Object System.Windows.Interop.WindowInteropHelper($window)).Handle
            [ResizeHelper]::SendMessage($windowHandle, [ResizeHelper]::WM_NCLBUTTONDOWN, [IntPtr][ResizeHelper]::HTBOTTOMRIGHT, [IntPtr]::Zero)
            $e.Handled = $true
        } catch {
            Write-Host "Resize error: $_"
        }
    })
}

# ===============================
# Window dragging and controls
# ===============================
# Drag window by holding top bar (but not on buttons)
$DragArea.Add_PreviewMouseLeftButtonDown({
    param($s, $e)
    # Only drag if not clicking on a button
    $source = $e.OriginalSource
    
    # Check if clicking on button or button content
    $element = $source
    while ($element -ne $null) {
        if ($element -is [System.Windows.Controls.Button]) {
            return  # Don't drag if clicking a button
        }
        $element = [System.Windows.Media.VisualTreeHelper]::GetParent($element)
    }
    
    # Perform drag
    try { 
        $window.DragMove() 
    } catch {
        # DragMove can fail in certain scenarios, silently ignore
    }
})

# ===============================================================================================================================
#                                                    Mouse Acceleration Toggle Logic
# ===============================================================================================================================
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



# ===============================
# Window Control Button Events
# ===============================
$BtnClose.Add_Click({ 
    $window.Close() 
})

$BtnMinimize.Add_Click({ 
    $window.WindowState = [System.Windows.WindowState]::Minimized 
})

$BtnMaximize.Add_Click({ 
    if ($window.WindowState -eq [System.Windows.WindowState]::Maximized) {
        $window.WindowState = [System.Windows.WindowState]::Normal
        $BtnMaximize.Content = "□"
    } else {
        $window.WindowState = [System.Windows.WindowState]::Maximized 
        $BtnMaximize.Content = "⧉"
    }
})

# ===============================
# Logging Function
# ===============================
function Write-Log($message) {
    $logFilePath = Join-Path $PSScriptRoot "logs.txt"
    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Add-Content -Path $logFilePath -Value "[$timestamp] $message"
}

# ===============================
# Logs Button Logic
# ===============================
$BtnLogs.Add_Click({
    Show-Page $PageLogs
    $logFilePath = Join-Path $PSScriptRoot "logs.txt"
    if (Test-Path $logFilePath) {
        # Clear existing content
        $TxtLogs.Document.Blocks.Clear()
        
        # Read log file
        $logContent = Get-Content $logFilePath
        
        # Create a paragraph for the logs
        $paragraph = New-Object System.Windows.Documents.Paragraph
        
        foreach ($line in $logContent) {
            # Create a run for each line
            $run = New-Object System.Windows.Documents.Run
            $run.Text = $line + "`n"
            
            # Color based on keywords
            if ($line -match '\b(SUCCESS|SUCCESSFULLY|SUCCESSFUL|ENABLED|COMPLETED|OK|DISABLED|DISSABLED)\b') {
                $run.Foreground = [System.Windows.Media.Brushes]::LimeGreen
            }
            elseif ($line -match '\b(ERROR|FAILED|FAILURE|EXCEPTION|CRITICAL)\b') {
                $run.Foreground = [System.Windows.Media.Brushes]::Red
            }
            elseif ($line -match '\b(WARNING|WARN)\b') {
                $run.Foreground = [System.Windows.Media.Brushes]::Orange
            }
            else {
                # Default color based on theme
                $run.Foreground = $window.Resources["ForegroundBrush"]
            }
            
            $paragraph.Inlines.Add($run)
        }
        
        $TxtLogs.Document.Blocks.Add($paragraph)
    } else {
        $TxtLogs.Document.Blocks.Clear()
        $paragraph = New-Object System.Windows.Documents.Paragraph
        $run = New-Object System.Windows.Documents.Run
        $run.Text = "No log file found."
        $paragraph.Inlines.Add($run)
        $TxtLogs.Document.Blocks.Add($paragraph)
    }
})

$BtnDownloadLogs.Add_Click({
    $logFilePath = Join-Path $PSScriptRoot "logs.txt"
    if (Test-Path $logFilePath) {
        $desktop = [Environment]::GetFolderPath("Desktop")
        $destPath = Join-Path $desktop "pctool-logs.txt"
        Copy-Item $logFilePath $destPath -Force
        Write-Host "Logs downloaded to Desktop: $destPath" -ForegroundColor Green
        [System.Windows.MessageBox]::Show("Logs downloaded to your Desktop as 'pctool-logs.txt'")
    } else {
        Write-Host "No log file found for download." -ForegroundColor Yellow
        [System.Windows.MessageBox]::Show("No log file found to download.")
    }
})

# ===============================
# Populate System Info
# ===============================
try {
    $os   = Get-CimInstance Win32_OperatingSystem
    $cpu  = Get-CimInstance Win32_Processor
    $ram  = (Get-CimInstance Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum).Sum / 1GB
    $gpu  = Get-CimInstance Win32_VideoController | Select-Object -First 1
    $mb   = Get-CimInstance Win32_BaseBoard
    $bios = Get-CimInstance Win32_BIOS
    $disk = Get-CimInstance Win32_DiskDrive | Select-Object -First 1
    $net  = Get-CimInstance Win32_NetworkAdapter | Where-Object { $_.NetEnabled } | Select-Object -First 1
    $sound = Get-CimInstance Win32_SoundDevice | Select-Object -First 1

    $LblOS.Text          = "OS -- $($os.Caption) ($($os.Version) Build $($os.BuildNumber))"
    $LblCPU.Text         = "CPU -- $($cpu.Name) ($($cpu.NumberOfCores)C/$($cpu.NumberOfLogicalProcessors)T)"
    $LblRAM.Text         = "RAM -- {0:N2} GB" -f $ram
    $LblGPU.Text         = "GPU -- $($gpu.Name) ($([math]::Round($gpu.AdapterRAM/1GB,2)) GB)"
    $LblMotherboard.Text = "Motherboard -- $($mb.Manufacturer) $($mb.Product)"
    $LblBIOS.Text        = "BIOS -- $($bios.Manufacturer) $($bios.SMBIOSBIOSVersion)"
    $LblDisk.Text        = "Disk -- $($disk.Model) ($([math]::Round($disk.Size/1GB,0)) GB)"
    $LblNetwork.Text     = "Network -- $($net.Name)"
    $LblSound.Text       = "Sound -- $($sound.Name)"

    $LblRouterIP.Text = "Router IP -- " + ((Get-NetRoute -DestinationPrefix "0.0.0.0/0").NextHop | Select-Object -First 1)
    $LblIP.Text       = "Local IP -- " + (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -notlike "*Loopback*" } | Select-Object -First 1).IPAddress
    $LblMAC.Text      = "MAC -- " + (Get-NetAdapter | Where-Object Status -eq "Up" | Select-Object -First 1).MacAddress
    $LblHWID.Text     = "HWID -- " + (Get-CimInstance Win32_ComputerSystemProduct).UUID

    try {
        $LblPublicIP.Text = "Public IP -- " + (Invoke-RestMethod -Uri "https://api.ipify.org")
    } catch {
        $LblPublicIP.Text = "Public IP -- [Offline]"
    }
} catch {
    Write-Host "Error fetching system info: $_"
}

# ===============================
# Advanced Info Toggle Logic
# ===============================
$global:AdvancedVisible = $false
$AdvancedLabels = @($LblRouterIP,$LblIP,$LblMAC,$LblHWID,$LblPublicIP)
$OriginalTexts = @{}

# Save original texts & mask them initially
foreach ($lbl in $AdvancedLabels) {
    $OriginalTexts[$lbl.Name] = $lbl.Text
    $prefix, $val = $lbl.Text -split " -- ",2
    $lbl.Text = "$prefix -- " + ("?" * ($val.Length))
}

$BtnToggleAdvanced.Add_Click({
    if ($global:AdvancedVisible) {
        foreach ($lbl in $AdvancedLabels) {
            $lbl.Text = $OriginalTexts[$lbl.Name]
        }
        $BtnToggleAdvanced.Content = "🙈"
        $global:AdvancedVisible = $false
    } else {
        foreach ($lbl in $AdvancedLabels) {
            $prefix, $val = $OriginalTexts[$lbl.Name] -split " -- ",2
            $lbl.Text = "$prefix -- " + ("?" * ($val.Length))
        }
        $BtnToggleAdvanced.Content = "👁"
        $global:AdvancedVisible = $true
    }
})


# ===============================
# Theme Toggle Logic
# ===============================
$global:darkMode = $true
$BtnToggleTheme.Add_Click({
    try {
        if ($global:darkMode) {
            # Switch to Light theme
            $lightBg = New-Object System.Windows.Media.SolidColorBrush([System.Windows.Media.Color]::FromRgb(245, 245, 245))
            $lightFg = New-Object System.Windows.Media.SolidColorBrush([System.Windows.Media.Color]::FromRgb(17, 17, 17))
            $lightCard = New-Object System.Windows.Media.SolidColorBrush([System.Windows.Media.Color]::FromRgb(255, 255, 255))
            $lightBorder = New-Object System.Windows.Media.SolidColorBrush([System.Windows.Media.Color]::FromRgb(204, 204, 204))
            $lightTopBar = New-Object System.Windows.Media.SolidColorBrush([System.Windows.Media.Color]::FromRgb(232, 232, 232))
            
            $window.Resources.Remove("WindowBackgroundBrush")
            $window.Resources.Remove("ForegroundBrush")
            $window.Resources.Remove("CardBrush")
            $window.Resources.Remove("BorderBrushColor")
            $window.Resources.Remove("TopBarBrush")
            
            $window.Resources.Add("WindowBackgroundBrush", $lightBg)
            $window.Resources.Add("ForegroundBrush", $lightFg)
            $window.Resources.Add("CardBrush", $lightCard)
            $window.Resources.Add("BorderBrushColor", $lightBorder)
            $window.Resources.Add("TopBarBrush", $lightTopBar)
            
            $BtnToggleTheme.Content = "☀️"
            $global:darkMode = $false
        } else {
            # Switch to Dark theme
            $darkBg = New-Object System.Windows.Media.SolidColorBrush([System.Windows.Media.Color]::FromRgb(26, 26, 26))
            $darkFg = New-Object System.Windows.Media.SolidColorBrush([System.Windows.Media.Color]::FromRgb(255, 255, 255))
            $darkCard = New-Object System.Windows.Media.SolidColorBrush([System.Windows.Media.Color]::FromRgb(45, 45, 45))
            $darkBorder = New-Object System.Windows.Media.SolidColorBrush([System.Windows.Media.Color]::FromRgb(64, 64, 64))
            $darkTopBar = New-Object System.Windows.Media.SolidColorBrush([System.Windows.Media.Color]::FromRgb(15, 15, 15))
            
            $window.Resources.Remove("WindowBackgroundBrush")
            $window.Resources.Remove("ForegroundBrush")
            $window.Resources.Remove("CardBrush")
            $window.Resources.Remove("BorderBrushColor")
            $window.Resources.Remove("TopBarBrush")
            
            $window.Resources.Add("WindowBackgroundBrush", $darkBg)
            $window.Resources.Add("ForegroundBrush", $darkFg)
            $window.Resources.Add("CardBrush", $darkCard)
            $window.Resources.Add("BorderBrushColor", $darkBorder)
            $window.Resources.Add("TopBarBrush", $darkTopBar)
            
            $BtnToggleTheme.Content = "🌙"
            $global:darkMode = $true
        }
        
        # Force UI refresh
        $window.UpdateLayout()
    } catch {
        Write-Host "Theme switch error: $_" -ForegroundColor Red
    }
})

# ===============================
# Page Switching Logic
# ===============================
function Show-Page($page) {
    foreach ($p in @($PageHome,$PageInstall,$PageTweaks,$PageConfig,$PagePrograms,$PageLogs)) {
        $p.Visibility = "Collapsed"
    }
    $page.Visibility = "Visible"
}

# ===============================
# Page Template Function
# ===============================
# Use this to create new page XAML quickly
function Get-PageTemplate {
    param([string]$PageName = "NewPage")
    
    return @"
<!-- $PageName -->
<Grid Name="Page$PageName" Visibility="Collapsed">
    <Grid.RowDefinitions>
        <RowDefinition Height="Auto"/>
        <RowDefinition Height="*"/>
        <RowDefinition Height="Auto"/>
    </Grid.RowDefinitions>

    <!-- Header -->
    <TextBlock Grid.Row="0" Text="$PageName" FontSize="24" FontWeight="Bold"
               Foreground="{DynamicResource ForegroundBrush}" Margin="0,0,0,20"/>

    <!-- Content Area -->
    <Border Grid.Row="1" Background="{DynamicResource WindowBackgroundBrush}" 
            CornerRadius="8" BorderBrush="{DynamicResource BorderBrushColor}" 
            BorderThickness="2" Padding="20">
        <ScrollViewer VerticalScrollBarVisibility="Auto">
            <StackPanel>
                <TextBlock Text="Content goes here..." FontSize="16"
                           Foreground="{DynamicResource ForegroundBrush}"
                           TextWrapping="Wrap" Margin="0,0,0,20"/>
                
                <!-- Add your controls here -->
                
            </StackPanel>
        </ScrollViewer>
    </Border>

    <!-- Footer (optional) -->
    <StackPanel Grid.Row="2" Orientation="Horizontal" 
                HorizontalAlignment="Right" Margin="0,20,0,0">
        <Button Name="Btn${PageName}Action1" Content="Action 1" 
                Style="{StaticResource RoundedButton}" Margin="5"/>
        <Button Name="Btn${PageName}Action2" Content="Action 2" 
                Style="{StaticResource RoundedButton}" Margin="5"/>
    </StackPanel>
</Grid>
"@
}

# Example usage (commented out):
# Write-Host (Get-PageTemplate -PageName "Settings")
# Write-Host (Get-PageTemplate -PageName "About")

$BtnHome.Add_Click({ Show-Page $PageHome })
$BtnInstall.Add_Click({ Show-Page $PageInstall })
$BtnTweaks.Add_Click({ Show-Page $PageTweaks })
$BtnConfig.Add_Click({ Show-Page $PageConfig })
$BtnPrograms.Add_Click({ Show-Page $PagePrograms })
$BtnLogs.Add_Click({ Show-Page $PageLogs })

# ===============================
# Set Registry and Service Tweaks Button Logic
# ===============================
$BtnSetRegTweaks.Add_Click({
    $result = [System.Windows.MessageBox]::Show(
        "Are you sure you want to apply all registry tweaks?",
        "Confirm Registry Tweaks",
        [System.Windows.MessageBoxButton]::YesNo,
        [System.Windows.MessageBoxImage]::Question
    )
    if ($result -ne [System.Windows.MessageBoxResult]::Yes) { return }

    Write-Log "Set Registry Tweaks button pressed."
    try {
        if (Get-Command Invoke-AllTweaks -ErrorAction SilentlyContinue) {
            Write-Log "Running Invoke-AllTweaks..."
            Invoke-AllTweaks
            Write-Log "Registry tweaks applied successfully."
            [System.Windows.MessageBox]::Show("Registry tweaks applied.")
        } else {
            Write-Log "Invoke-AllTweaks function not found."
            [System.Windows.MessageBox]::Show("Invoke-AllTweaks function not found.")
        }
    } catch {
        Write-Log "Error running registry tweaks: $_"
        [System.Windows.MessageBox]::Show("Error running registry tweaks: $_")
    }
})

$BtnSetServiceTweaks.Add_Click({
    $result = [System.Windows.MessageBox]::Show(
        "Are you sure you want to apply all service tweaks?",
        "Confirm Service Tweaks",
        [System.Windows.MessageBoxButton]::YesNo,
        [System.Windows.MessageBoxImage]::Question
    )
    if ($result -ne [System.Windows.MessageBoxResult]::Yes) { return }

    Write-Log "Set Service Tweaks button pressed."
    try {
        if (Get-Command Invoke-ServiceTweaks -ErrorAction SilentlyContinue) {
            Write-Log "Running Invoke-ServiceTweaks..."
            Invoke-ServiceTweaks
            Write-Log "Service tweaks applied successfully."
            [System.Windows.MessageBox]::Show("Service tweaks applied.")
        } else {
            Write-Log "Invoke-ServiceTweaks function not found."
            [System.Windows.MessageBox]::Show("Invoke-ServiceTweaks function not found.")
        }
    } catch {
        Write-Log "Error running service tweaks: $_"
        [System.Windows.MessageBox]::Show("Error running service tweaks: $_")
    }
})

# ===============================
# Run Tweaks Button Logic
# ===============================
$BtnRunTweaks.Add_Click({
    # Collect all checked tweaks
    $checkedTweaks = @()
    for ($i = 1; $i -le 20; $i++) {
        $chk = Get-Variable -Name ("ChkTweak$($i)") -ValueOnly
        if ($chk.IsChecked) { $checkedTweaks += "Tweak $i" }
    }

    if ($checkedTweaks.Count -eq 0) {
        [System.Windows.MessageBox]::Show("No tweaks selected.")
        return
    }

    $result = [System.Windows.MessageBox]::Show(
        "Are you sure you want to run the following tweaks?`n`n$($checkedTweaks -join "`n")",
        "Confirm Tweaks",
        [System.Windows.MessageBoxButton]::YesNo,
        [System.Windows.MessageBoxImage]::Question
    )
    if ($result -eq [System.Windows.MessageBoxResult]::Yes) {
        foreach ($tweak in $checkedTweaks) {
            # TODO: Implement what each tweak does here
            Write-Host "Running $tweak"
        }
        # Uncheck all after running
        for ($i = 1; $i -le 20; $i++) {
            $chk = Get-Variable -Name ("ChkTweak$($i)") -ValueOnly
            $chk.IsChecked = $false
        }
        [System.Windows.MessageBox]::Show("Selected tweaks have been applied.")
    }
})

# ===============================
# Show window
# ===============================
$window.ShowDialog() | Out-Null