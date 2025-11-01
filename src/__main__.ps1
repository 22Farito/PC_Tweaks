# ===============================================================================================================================
#                                                           ADVANCED TWEAKS
# ===============================================================================================================================
# Custom themed confirmation dialog
function Show-ConfirmationDialog {
    param(
        [string]$Title,
        [string[]]$Items
    )
    
    $dialogXaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="$Title"
        WindowStyle="None"
        AllowsTransparency="True"
        Background="Transparent"
        Width="600" Height="500"
        WindowStartupLocation="CenterScreen"
        ResizeMode="NoResize">
    <Window.Resources>
        <Color x:Key="DarkBackgroundColor">#1A1A1A</Color>
        <Color x:Key="DarkCardColor">#2D2D2D</Color>
        <Color x:Key="DarkBorderColor">#404040</Color>
        <SolidColorBrush x:Key="WindowBackgroundBrush" Color="{StaticResource DarkBackgroundColor}"/>
        <SolidColorBrush x:Key="CardBrush" Color="{StaticResource DarkCardColor}"/>
        <SolidColorBrush x:Key="BorderBrushColor" Color="{StaticResource DarkBorderColor}"/>
        <SolidColorBrush x:Key="AccentBrush" Color="#4F8EF7"/>
        
        <Style x:Key="DialogButton" TargetType="Button">
            <Setter Property="FontWeight" Value="Bold"/>
            <Setter Property="FontSize" Value="15"/>
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="Background" Value="{StaticResource CardBrush}"/>
            <Setter Property="BorderBrush" Value="{StaticResource AccentBrush}"/>
            <Setter Property="BorderThickness" Value="2"/>
            <Setter Property="Height" Value="44"/>
            <Setter Property="Padding" Value="30,0"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border CornerRadius="10"
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
    
    <Border CornerRadius="15" Background="{StaticResource CardBrush}" 
            BorderBrush="{StaticResource BorderBrushColor}" BorderThickness="2">
        <Grid Margin="30">
            <Grid.RowDefinitions>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="*"/>
                <RowDefinition Height="Auto"/>
            </Grid.RowDefinitions>
            
            <!-- Warning Icon & Title -->
            <StackPanel Grid.Row="0" Orientation="Horizontal" Margin="0,0,0,20">
                <TextBlock Text="⚠" FontSize="32" Foreground="#FF9800" VerticalAlignment="Center" Margin="0,0,15,0"/>
                <TextBlock Text="$Title" FontSize="22" FontWeight="Bold" Foreground="White" VerticalAlignment="Center"/>
            </StackPanel>
            
            <!-- Description -->
            <TextBlock Grid.Row="1" Text="The following tweaks will be applied:" 
                       FontSize="14" Foreground="#CCCCCC" Margin="0,0,0,15"/>
            
            <!-- Scrollable List -->
            <Border Grid.Row="2" Background="{StaticResource WindowBackgroundBrush}" 
                    CornerRadius="8" BorderBrush="{StaticResource BorderBrushColor}" BorderThickness="1"
                    Margin="0,0,0,25">
                <ScrollViewer VerticalScrollBarVisibility="Auto" Margin="15">
                    <StackPanel Name="ItemsList"/>
                </ScrollViewer>
            </Border>
            
            <!-- Buttons -->
            <Grid Grid.Row="3">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="15"/>
                    <ColumnDefinition Width="*"/>
                </Grid.ColumnDefinitions>
                <Button Grid.Column="0" Name="BtnYes" Content="Yes, Apply Tweaks" Style="{StaticResource DialogButton}"/>
                <Button Grid.Column="2" Name="BtnNo" Content="Cancel" Style="{StaticResource DialogButton}" 
                        BorderBrush="#666666"/>
            </Grid>
        </Grid>
    </Border>
</Window>
"@
## BtnConfigRecommended removed from XAML

    try {
        $dialogWindow = [Windows.Markup.XamlReader]::Parse($dialogXaml)
        $itemsList = $dialogWindow.FindName("ItemsList")
        $btnYes = $dialogWindow.FindName("BtnYes")
        $btnNo = $dialogWindow.FindName("BtnNo")
        
        # Add items to list
        foreach ($item in $Items) {
            $textBlock = New-Object System.Windows.Controls.TextBlock
            $textBlock.Text = "- $item"
            $textBlock.FontSize = 14
            $textBlock.Foreground = [System.Windows.Media.Brushes]::White
            $textBlock.Margin = "0,0,0,8"
            $textBlock.TextWrapping = [System.Windows.TextWrapping]::Wrap
            $itemsList.Children.Add($textBlock) | Out-Null
        }
        
        # Button handlers
        $dialogResult = $false
        $btnYes.Add_Click({
            $script:dialogResult = $true
            $dialogWindow.Close()
        })
        $btnNo.Add_Click({
            $script:dialogResult = $false
            $dialogWindow.Close()
        })
        
        # Show dialog
        $dialogWindow.ShowDialog() | Out-Null
        return $script:dialogResult
    } catch {
        Write-Log "Error showing confirmation dialog: $_"
        # Fallback to standard MessageBox
        $tweakList = $Items -join "`n  - "
        $result = [System.Windows.MessageBox]::Show("The following tweaks will be applied:`n`n  - $tweakList`n`nAre you sure?", $Title, 
            [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Warning)
        return ($result -eq [System.Windows.MessageBoxResult]::Yes)
    }
}


# Wrapper for invoking external commands with logging
function Invoke-ExternalCommand {
    param([Parameter(Mandatory)][string]$Command)
    try {
        Write-Log "RUN: $Command"
        $null = Invoke-Expression $Command
        $exitCode = $LASTEXITCODE
        if ($exitCode -eq 0) {
            Write-Host "[SUCCESS] $Command" -ForegroundColor Green
        } else {
            Write-Host "[ERROR] $Command (exit $exitCode)" -ForegroundColor Red
        }
    } catch {
        Write-Host "[EXCEPTION] $Command -> $_" -ForegroundColor Yellow
        Write-Log "[EXCEPTION] $Command -> $_"
    }
}

# Check if running with administrative privileges
function Test-IsAdministrator {
    try {
        $currentIdentity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = New-Object System.Security.Principal.WindowsPrincipal($currentIdentity)
        return $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
    } catch {
        Write-Log "[WARN] Unable to determine Administrator status: $_"
        return $false
    }
}

# Disable IPv6
function Disable-IPv6 {
    Write-Host "Disabling IPv6..." -ForegroundColor Cyan
    Write-Log "Disabling IPv6"
    try {
        Invoke-ExternalCommand "netsh interface ipv6 set disabledcomponents 0xFF"
        Write-Host "[SUCCESS] IPv6 disabled" -ForegroundColor Green
        Write-Log "[SUCCESS] IPv6 disabled"
    } catch {
        Write-Host "[ERROR] Failed to disable IPv6: $_" -ForegroundColor Red
        Write-Log "[ERROR] Failed to disable IPv6: $_"
    }
}

# Block Adobe Network
function Block-AdobeNetwork {
    Write-Host "Blocking Adobe Network..." -ForegroundColor Cyan
    Write-Log "Blocking Adobe Network"
    try {
        $hostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"
        $adobeHosts = @"

# Adobe Activation Block
127.0.0.1 lm.licenses.adobe.com
127.0.0.1 lmlicenses.wip4.adobe.com
127.0.0.1 na1r.services.adobe.com
127.0.0.1 hlrcv.stage.adobe.com
127.0.0.1 practivate.adobe.com
127.0.0.1 activate.adobe.com
"@
        Add-Content -Path $hostsPath -Value $adobeHosts -Force
        Write-Host "[SUCCESS] Adobe Network blocked" -ForegroundColor Green
        Write-Log "[SUCCESS] Adobe Network blocked"
    } catch {
        Write-Host "[ERROR] Failed to block Adobe Network: $_" -ForegroundColor Red
        Write-Log "[ERROR] Failed to block Adobe Network: $_"
    }
}

# Debloat Adobe
function Optimize-Adobe {
    Write-Host "Debloating Adobe..." -ForegroundColor Cyan
    Write-Log "Debloating Adobe"
    try {
        $adobeProcesses = @("CCXProcess", "CCLibrary", "AdobeIPCBroker", "Adobe Desktop Service", "AdobeGCClient")
        foreach ($proc in $adobeProcesses) {
            Stop-Process -Name $proc -Force -ErrorAction SilentlyContinue
        }
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Adobe\Acrobat Reader\DC\FeatureLockDown" -Name "bUpdater" -Value 0 -Force -ErrorAction SilentlyContinue
        Write-Host "[SUCCESS] Adobe debloated" -ForegroundColor Green
        Write-Log "[SUCCESS] Adobe debloated"
    } catch {
        Write-Host "[ERROR] Failed to debloat Adobe: $_" -ForegroundColor Red
        Write-Log "[ERROR] Failed to debloat Adobe: $_"
    }
}

# Prefer IPv4 over IPv6
function Set-IPv4Preference {
    Write-Host "Preferring IPv4 over IPv6..." -ForegroundColor Cyan
    Write-Log "Preferring IPv4 over IPv6"
    try {
        Invoke-ExternalCommand "netsh interface ipv6 set prefixpolicy ::1/128 50 0"
        Invoke-ExternalCommand "netsh interface ipv6 set prefixpolicy ::/0 40 1"
        Write-Host "[SUCCESS] IPv4 preferred over IPv6" -ForegroundColor Green
        Write-Log "[SUCCESS] IPv4 preferred over IPv6"
    } catch {
        Write-Host "[ERROR] Failed to prefer IPv4: $_" -ForegroundColor Red
        Write-Log "[ERROR] Failed to prefer IPv4: $_"
    }
}

# Disable Teredo
function Disable-Teredo {
    Write-Host "Disabling Teredo..." -ForegroundColor Cyan
    Write-Log "Disabling Teredo"
    try {
        Invoke-ExternalCommand "netsh interface teredo set state disabled"
        Write-Host "[SUCCESS] Teredo disabled" -ForegroundColor Green
        Write-Log "[SUCCESS] Teredo disabled"
    } catch {
        Write-Host "[ERROR] Failed to disable Teredo: $_" -ForegroundColor Red
        Write-Log "[ERROR] Failed to disable Teredo: $_"
    }
}

# Disable Background Apps
function Disable-BackgroundApps {
    Write-Host "Disabling Background Apps..." -ForegroundColor Cyan
    Write-Log "Disabling Background Apps"
    try {
        Set-RegistryValue -Root "HKEY_CURRENT_USER" -Path "Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" -Name "GlobalUserDisabled" -Value 1
        Write-Host "[SUCCESS] Background Apps disabled" -ForegroundColor Green
        Write-Log "[SUCCESS] Background Apps disabled"
    } catch {
        Write-Host "[ERROR] Failed to disable Background Apps: $_" -ForegroundColor Red
        Write-Log "[ERROR] Failed to disable Background Apps: $_"
    }
}

# Disable Fullscreen Optimizations
function Disable-FullscreenOptimizations {
    Write-Host "Disabling Fullscreen Optimizations..." -ForegroundColor Cyan
    Write-Log "Disabling Fullscreen Optimizations"
    try {
        Set-RegistryValue -Root "HKEY_CURRENT_USER" -Path "System\GameConfigStore" -Name "GameDVR_DXGIHonorFSEWindowsCompatible" -Value 1
        Set-RegistryValue -Root "HKEY_CURRENT_USER" -Path "System\GameConfigStore" -Name "GameDVR_FSEBehavior" -Value 2
        Write-Host "[SUCCESS] Fullscreen Optimizations disabled" -ForegroundColor Green
        Write-Log "[SUCCESS] Fullscreen Optimizations disabled"
    } catch {
        Write-Host "[ERROR] Failed to disable Fullscreen Optimizations: $_" -ForegroundColor Red
        Write-Log "[ERROR] Failed to disable Fullscreen Optimizations: $_"
    }
}

# Disable Microsoft Copilot
function Disable-Copilot {
    Write-Host "Disabling Microsoft Copilot..." -ForegroundColor Cyan
    Write-Log "Disabling Microsoft Copilot"
    try {
        Set-RegistryValue -Root "HKEY_CURRENT_USER" -Path "Software\Policies\Microsoft\Windows\WindowsCopilot" -Name "TurnOffWindowsCopilot" -Value 1
        Set-RegistryValue -Root "HKEY_LOCAL_MACHINE" -Path "SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" -Name "TurnOffWindowsCopilot" -Value 1
        Write-Host "[SUCCESS] Microsoft Copilot disabled" -ForegroundColor Green
        Write-Log "[SUCCESS] Microsoft Copilot disabled"
    } catch {
        Write-Host "[ERROR] Failed to disable Copilot: $_" -ForegroundColor Red
        Write-Log "[ERROR] Failed to disable Copilot: $_"
    }
}

# Disable Intel MM (vPro LMS)
function Disable-IntelMM {
    Write-Host "Disabling Intel MM (vPro LMS)..." -ForegroundColor Cyan
    Write-Log "Disabling Intel MM"
    try {
        Stop-Service -Name "LMS" -Force -ErrorAction SilentlyContinue
        Set-Service -Name "LMS" -StartupType Disabled -ErrorAction SilentlyContinue
        Write-Host "[SUCCESS] Intel MM disabled" -ForegroundColor Green
        Write-Log "[SUCCESS] Intel MM disabled"
    } catch {
        Write-Host "[ERROR] Failed to disable Intel MM: $_" -ForegroundColor Red
        Write-Log "[ERROR] Failed to disable Intel MM: $_"
    }
}

# Disable Notification Tray/Calendar
function Disable-NotificationTray {
    Write-Host "Disabling Notification Tray/Calendar..." -ForegroundColor Cyan
    Write-Log "Disabling Notification Tray/Calendar"
    try {
        Set-RegistryValue -Root "HKEY_CURRENT_USER" -Path "Software\Policies\Microsoft\Windows\Explorer" -Name "DisableNotificationCenter" -Value 1
        Set-RegistryValue -Root "HKEY_LOCAL_MACHINE" -Path "SOFTWARE\Policies\Microsoft\Windows\Explorer" -Name "DisableNotificationCenter" -Value 1
        Write-Host "[SUCCESS] Notification Tray disabled" -ForegroundColor Green
        Write-Log "[SUCCESS] Notification Tray disabled"
    } catch {
        Write-Host "[ERROR] Failed to disable Notification Tray: $_" -ForegroundColor Red
        Write-Log "[ERROR] Failed to disable Notification Tray: $_"
    }
}

# Disable WPBT
function Disable-WPBT {
    Write-Host "Disabling WPBT..." -ForegroundColor Cyan
    Write-Log "Disabling WPBT"
    try {
        Set-RegistryValue -Root "HKEY_LOCAL_MACHINE" -Path "SYSTEM\CurrentControlSet\Control\Session Manager" -Name "DisableWpbtExecution" -Value 1
        Write-Host "[SUCCESS] WPBT disabled" -ForegroundColor Green
        Write-Log "[SUCCESS] WPBT disabled"
    } catch {
        Write-Host "[ERROR] Failed to disable WPBT: $_" -ForegroundColor Red
        Write-Log "[ERROR] Failed to disable WPBT: $_"
    }
}

# Set Display for Performance
function Set-DisplayPerformance {
    Write-Host "Setting Display for Performance..." -ForegroundColor Cyan
    Write-Log "Setting Display for Performance"
    try {
        Set-RegistryValue -Root "HKEY_CURRENT_USER" -Path "Control Panel\Desktop" -Name "UserPreferencesMask" -Value ([byte[]](0x90,0x12,0x03,0x80,0x10,0x00,0x00,0x00)) -ValueType ([Microsoft.Win32.RegistryValueKind]::Binary)
        Set-RegistryValue -Root "HKEY_CURRENT_USER" -Path "Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Value 2
        Write-Host "[SUCCESS] Display set for Performance" -ForegroundColor Green
        Write-Log "[SUCCESS] Display set for Performance"
    } catch {
        Write-Host "[ERROR] Failed to set Display for Performance: $_" -ForegroundColor Red
        Write-Log "[ERROR] Failed to set Display for Performance: $_"
    }
}

# Set Classic Right-Click Menu
function Set-ClassicContextMenu {
    Write-Host "Setting Classic Right-Click Menu..." -ForegroundColor Cyan
    Write-Log "Setting Classic Right-Click Menu"
    try {
        Set-RegistryValue -Root "HKEY_CURRENT_USER" -Path "Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" -Name "(Default)" -Value "" -ValueType ([Microsoft.Win32.RegistryValueKind]::String)
        Write-Host "[SUCCESS] Classic Right-Click Menu set" -ForegroundColor Green
        Write-Log "[SUCCESS] Classic Right-Click Menu set"
    } catch {
        Write-Host "[ERROR] Failed to set Classic Right-Click Menu: $_" -ForegroundColor Red
        Write-Log "[ERROR] Failed to set Classic Right-Click Menu: $_"
    }
}

# Set Time to UTC
function Set-TimeUTC {
    Write-Host "Setting Time to UTC..." -ForegroundColor Cyan
    Write-Log "Setting Time to UTC"
    try {
        Set-RegistryValue -Root "HKEY_LOCAL_MACHINE" -Path "SYSTEM\CurrentControlSet\Control\TimeZoneInformation" -Name "RealTimeIsUniversal" -Value 1
        Write-Host "[SUCCESS] Time set to UTC" -ForegroundColor Green
        Write-Log "[SUCCESS] Time set to UTC"
    } catch {
        Write-Host "[ERROR] Failed to set Time to UTC: $_" -ForegroundColor Red
        Write-Log "[ERROR] Failed to set Time to UTC: $_"
    }
}

# Remove ALL MS Store Apps
function Remove-MSStoreApps {
    Write-Host "Removing ALL MS Store Apps..." -ForegroundColor Yellow
    Write-Log "Removing ALL MS Store Apps"
    try {
        Get-AppxPackage -AllUsers | Where-Object {$_.Name -notlike "*Store*" -and $_.Name -notlike "*Calculator*"} | Remove-AppxPackage -ErrorAction SilentlyContinue
        Write-Host "[SUCCESS] MS Store Apps removed" -ForegroundColor Green
        Write-Log "[SUCCESS] MS Store Apps removed"
    } catch {
        Write-Host "[ERROR] Failed to remove MS Store Apps: $_" -ForegroundColor Red
        Write-Log "[ERROR] Failed to remove MS Store Apps: $_"
    }
}

# Remove Home from Explorer
function Remove-HomeFromExplorer {
    Write-Host "Removing Home from Explorer..." -ForegroundColor Cyan
    Write-Log "Removing Home from Explorer"
    try {
        Set-RegistryValue -Root "HKEY_LOCAL_MACHINE" -Path "SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\{f874310e-b6b7-47dc-bc84-b9e6b38f5903}" -Name "(Default)" -Value "" -ValueType ([Microsoft.Win32.RegistryValueKind]::String)
        Remove-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\{f874310e-b6b7-47dc-bc84-b9e6b38f5903}" -Force -ErrorAction SilentlyContinue
        Write-Host "[SUCCESS] Home removed from Explorer" -ForegroundColor Green
        Write-Log "[SUCCESS] Home removed from Explorer"
    } catch {
        Write-Host "[ERROR] Failed to remove Home from Explorer: $_" -ForegroundColor Red
        Write-Log "[ERROR] Failed to remove Home from Explorer: $_"
    }
}

# Remove Gallery from Explorer
function Remove-GalleryFromExplorer {
    Write-Host "Removing Gallery from Explorer..." -ForegroundColor Cyan
    Write-Log "Removing Gallery from Explorer"
    try {
        Set-RegistryValue -Root "HKEY_LOCAL_MACHINE" -Path "SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\{e88865ea-0e1c-4e20-9aa6-edcd0212c87c}" -Name "(Default)" -Value "" -ValueType ([Microsoft.Win32.RegistryValueKind]::String)
        Remove-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\{e88865ea-0e1c-4e20-9aa6-edcd0212c87c}" -Force -ErrorAction SilentlyContinue
        Write-Host "[SUCCESS] Gallery removed from Explorer" -ForegroundColor Green
        Write-Log "[SUCCESS] Gallery removed from Explorer"
    } catch {
        Write-Host "[ERROR] Failed to remove Gallery from Explorer: $_" -ForegroundColor Red
        Write-Log "[ERROR] Failed to remove Gallery from Explorer: $_"
    }
}

# Remove OneDrive
function Remove-OneDrive {
    Write-Host "Removing OneDrive..." -ForegroundColor Cyan
    Write-Log "Removing OneDrive"
    try {
        Stop-Process -Name "OneDrive" -Force -ErrorAction SilentlyContinue
        Start-Process -FilePath "C:\Windows\SysWOW64\OneDriveSetup.exe" -ArgumentList "/uninstall" -Wait -WindowStyle Hidden -ErrorAction SilentlyContinue
        Remove-Item -Path "$env:USERPROFILE\OneDrive" -Force -Recurse -ErrorAction SilentlyContinue
        Set-RegistryValue -Root "HKEY_CLASSES_ROOT" -Path "CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" -Name "System.IsPinnedToNameSpaceTree" -Value 0
        Write-Host "[SUCCESS] OneDrive removed" -ForegroundColor Green
        Write-Log "[SUCCESS] OneDrive removed"
    } catch {
        Write-Host "[ERROR] Failed to remove OneDrive: $_" -ForegroundColor Red
        Write-Log "[ERROR] Failed to remove OneDrive: $_"
    }
}

# Block Razer Software
function Block-RazerSoftware {
    Write-Host "Blocking Razer Software..." -ForegroundColor Cyan
    Write-Log "Blocking Razer Software"
    try {
        $hostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"
        $razerHosts = @"

# Razer Block
127.0.0.1 razer.com
127.0.0.1 assets.razerzone.com
127.0.0.1 dl.razerzone.com
"@
        Add-Content -Path $hostsPath -Value $razerHosts -Force
        Write-Host "[SUCCESS] Razer Software blocked" -ForegroundColor Green
        Write-Log "[SUCCESS] Razer Software blocked"
    } catch {
        Write-Host "[ERROR] Failed to block Razer Software: $_" -ForegroundColor Red
        Write-Log "[ERROR] Failed to block Razer Software: $_"
    }
}

# Create Restore Point
function New-RestorePoint {
    Write-Host "Creating Restore Point..." -ForegroundColor Cyan
    Write-Log "Creating Restore Point"
    try {
        Checkpoint-Computer -Description "PC Tweaks - $(Get-Date -Format 'yyyy-MM-dd HH:mm')" -RestorePointType "MODIFY_SETTINGS"
        Write-Host "[SUCCESS] Restore Point created" -ForegroundColor Green
        Write-Log "[SUCCESS] Restore Point created"
    } catch {
        Write-Host "[ERROR] Failed to create Restore Point: $_" -ForegroundColor Red
        Write-Log "[ERROR] Failed to create Restore Point: $_"
    }
}

# Delete Temporary Files
function Clear-TempFiles {
    Write-Host "Deleting Temporary Files..." -ForegroundColor Cyan
    Write-Log "Deleting Temporary Files"
    try {
        Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "[SUCCESS] Temporary Files deleted" -ForegroundColor Green
        Write-Log "[SUCCESS] Temporary Files deleted"
    } catch {
        Write-Host "[ERROR] Failed to delete Temporary Files: $_" -ForegroundColor Red
        Write-Log "[ERROR] Failed to delete Temporary Files: $_"
    }
}

# Disable ConsumerFeatures
function Disable-ConsumerFeatures {
    Write-Host "Disabling ConsumerFeatures..." -ForegroundColor Cyan
    Write-Log "Disabling ConsumerFeatures"
    try {
        Set-RegistryValue -Root "HKEY_LOCAL_MACHINE" -Path "SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableWindowsConsumerFeatures" -Value 1
        Write-Host "[SUCCESS] ConsumerFeatures disabled" -ForegroundColor Green
        Write-Log "[SUCCESS] ConsumerFeatures disabled"
    } catch {
        Write-Host "[ERROR] Failed to disable ConsumerFeatures: $_" -ForegroundColor Red
        Write-Log "[ERROR] Failed to disable ConsumerFeatures: $_"
    }
}

# Disable Telemetry
function Disable-Telemetry {
    Write-Host "Disabling Telemetry..." -ForegroundColor Cyan
    Write-Log "Disabling Telemetry"
    try {
        Set-RegistryValue -Root "HKEY_LOCAL_MACHINE" -Path "SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value 0
        Set-RegistryValue -Root "HKEY_LOCAL_MACHINE" -Path "SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" -Name "AllowTelemetry" -Value 0
        Stop-Service -Name "DiagTrack" -Force -ErrorAction SilentlyContinue
        Set-Service -Name "DiagTrack" -StartupType Disabled -ErrorAction SilentlyContinue
        Write-Host "[SUCCESS] Telemetry disabled" -ForegroundColor Green
        Write-Log "[SUCCESS] Telemetry disabled"
    } catch {
        Write-Host "[ERROR] Failed to disable Telemetry: $_" -ForegroundColor Red
        Write-Log "[ERROR] Failed to disable Telemetry: $_"
    }
}

# Disable Activity History
function Disable-ActivityHistory {
    Write-Host "Disabling Activity History..." -ForegroundColor Cyan
    Write-Log "Disabling Activity History"
    try {
        Set-RegistryValue -Root "HKEY_LOCAL_MACHINE" -Path "SOFTWARE\Policies\Microsoft\Windows\System" -Name "EnableActivityFeed" -Value 0
        Set-RegistryValue -Root "HKEY_LOCAL_MACHINE" -Path "SOFTWARE\Policies\Microsoft\Windows\System" -Name "PublishUserActivities" -Value 0
        Set-RegistryValue -Root "HKEY_LOCAL_MACHINE" -Path "SOFTWARE\Policies\Microsoft\Windows\System" -Name "UploadUserActivities" -Value 0
        Write-Host "[SUCCESS] Activity History disabled" -ForegroundColor Green
        Write-Log "[SUCCESS] Activity History disabled"
    } catch {
        Write-Host "[ERROR] Failed to disable Activity History: $_" -ForegroundColor Red
        Write-Log "[ERROR] Failed to disable Activity History: $_"
    }
}

# Disable Explorer Automatic Folder Discovery
function Disable-ExplorerFolderDiscovery {
    Write-Host "Disabling Explorer Automatic Folder Discovery..." -ForegroundColor Cyan
    Write-Log "Disabling Explorer Automatic Folder Discovery"
    try {
        Set-RegistryValue -Root "HKEY_CURRENT_USER" -Path "Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\Bags\AllFolders\Shell" -Name "FolderType" -Value "NotSpecified" -ValueType ([Microsoft.Win32.RegistryValueKind]::String)
        Write-Host "[SUCCESS] Explorer Automatic Folder Discovery disabled" -ForegroundColor Green
        Write-Log "[SUCCESS] Explorer Automatic Folder Discovery disabled"
    } catch {
        Write-Host "[ERROR] Failed to disable Explorer Automatic Folder Discovery: $_" -ForegroundColor Red
        Write-Log "[ERROR] Failed to disable Explorer Automatic Folder Discovery: $_"
    }
}

# Disable GameDVR
function Disable-GameDVR {
    Write-Host "Disabling GameDVR..." -ForegroundColor Cyan
    Write-Log "Disabling GameDVR"
    try {
        Set-RegistryValue -Root "HKEY_CURRENT_USER" -Path "System\GameConfigStore" -Name "GameDVR_Enabled" -Value 0
        Set-RegistryValue -Root "HKEY_LOCAL_MACHINE" -Path "SOFTWARE\Policies\Microsoft\Windows\GameDVR" -Name "AllowGameDVR" -Value 0
        Write-Host "[SUCCESS] GameDVR disabled" -ForegroundColor Green
        Write-Log "[SUCCESS] GameDVR disabled"
    } catch {
        Write-Host "[ERROR] Failed to disable GameDVR: $_" -ForegroundColor Red
        Write-Log "[ERROR] Failed to disable GameDVR: $_"
    }
}

# Disable Hibernation
function Disable-Hibernation {
    Write-Host "Disabling Hibernation..." -ForegroundColor Cyan
    Write-Log "Disabling Hibernation"
    try {
        Invoke-ExternalCommand "powercfg.exe /hibernate off"
        Write-Host "[SUCCESS] Hibernation disabled" -ForegroundColor Green
        Write-Log "[SUCCESS] Hibernation disabled"
    } catch {
        Write-Host "[ERROR] Failed to disable Hibernation: $_" -ForegroundColor Red
        Write-Log "[ERROR] Failed to disable Hibernation: $_"
    }
}

# Disable Homegroup
function Disable-Homegroup {
    Write-Host "Disabling Homegroup..." -ForegroundColor Cyan
    Write-Log "Disabling Homegroup"
    try {
        Stop-Service -Name "HomeGroupListener" -Force -ErrorAction SilentlyContinue
        Set-Service -Name "HomeGroupListener" -StartupType Disabled -ErrorAction SilentlyContinue
        Stop-Service -Name "HomeGroupProvider" -Force -ErrorAction SilentlyContinue
        Set-Service -Name "HomeGroupProvider" -StartupType Disabled -ErrorAction SilentlyContinue
        Write-Host "[SUCCESS] Homegroup disabled" -ForegroundColor Green
        Write-Log "[SUCCESS] Homegroup disabled"
    } catch {
        Write-Host "[ERROR] Failed to disable Homegroup: $_" -ForegroundColor Red
        Write-Log "[ERROR] Failed to disable Homegroup: $_"
    }
}

# Disable Location Tracking
function Disable-LocationTracking {
    Write-Host "Disabling Location Tracking..." -ForegroundColor Cyan
    Write-Log "Disabling Location Tracking"
    try {
        Set-RegistryValue -Root "HKEY_LOCAL_MACHINE" -Path "SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" -Name "Value" -Value "Deny" -ValueType ([Microsoft.Win32.RegistryValueKind]::String)
        Set-RegistryValue -Root "HKEY_LOCAL_MACHINE" -Path "SYSTEM\CurrentControlSet\Services\lfsvc\Service\Configuration" -Name "Status" -Value 0
        Write-Host "[SUCCESS] Location Tracking disabled" -ForegroundColor Green
        Write-Log "[SUCCESS] Location Tracking disabled"
    } catch {
        Write-Host "[ERROR] Failed to disable Location Tracking: $_" -ForegroundColor Red
        Write-Log "[ERROR] Failed to disable Location Tracking: $_"
    }
}

# Disable Storage Sense
function Disable-StorageSense {
    Write-Host "Disabling Storage Sense..." -ForegroundColor Cyan
    Write-Log "Disabling Storage Sense"
    try {
        Set-RegistryValue -Root "HKEY_CURRENT_USER" -Path "Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" -Name "01" -Value 0
        Write-Host "[SUCCESS] Storage Sense disabled" -ForegroundColor Green
        Write-Log "[SUCCESS] Storage Sense disabled"
    } catch {
        Write-Host "[ERROR] Failed to disable Storage Sense: $_" -ForegroundColor Red
        Write-Log "[ERROR] Failed to disable Storage Sense: $_"
    }
}

# Disable Wifi-Sense
function Disable-WifiSense {
    Write-Host "Disabling Wifi-Sense..." -ForegroundColor Cyan
    Write-Log "Disabling Wifi-Sense"
    try {
        Set-RegistryValue -Root "HKEY_LOCAL_MACHINE" -Path "SOFTWARE\Microsoft\PolicyManager\default\WiFi\AllowWiFiHotSpotReporting" -Name "Value" -Value 0
        Set-RegistryValue -Root "HKEY_LOCAL_MACHINE" -Path "SOFTWARE\Microsoft\PolicyManager\default\WiFi\AllowAutoConnectToWiFiSenseHotspots" -Name "Value" -Value 0
        Write-Host "[SUCCESS] Wifi-Sense disabled" -ForegroundColor Green
        Write-Log "[SUCCESS] Wifi-Sense disabled"
    } catch {
        Write-Host "[ERROR] Failed to disable Wifi-Sense: $_" -ForegroundColor Red
        Write-Log "[ERROR] Failed to disable Wifi-Sense: $_"
    }
}

# Enable End Task With Right Click
function Enable-EndTaskRightClick {
    Write-Host "Enabling End Task With Right Click..." -ForegroundColor Cyan
    Write-Log "Enabling End Task With Right Click"
    try {
        Set-RegistryValue -Root "HKEY_CURRENT_USER" -Path "Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDeveloperSettings" -Name "TaskbarEndTask" -Value 1
        Write-Host "[SUCCESS] End Task With Right Click enabled" -ForegroundColor Green
        Write-Log "[SUCCESS] End Task With Right Click enabled"
    } catch {
        Write-Host "[ERROR] Failed to enable End Task With Right Click: $_" -ForegroundColor Red
        Write-Log "[ERROR] Failed to enable End Task With Right Click: $_"
    }
}

# Run Disk Cleanup
function Start-DiskCleanup {
    Write-Host "Running Disk Cleanup..." -ForegroundColor Cyan
    Write-Log "Running Disk Cleanup"
    try {
    # Ensure recommended categories are configured for profile 1
    Set-DiskCleanupRecommendations -SageProfile 1
        Start-Process -FilePath "cleanmgr.exe" -ArgumentList "/sagerun:1" -Wait -WindowStyle Hidden
        Write-Host "[SUCCESS] Disk Cleanup completed" -ForegroundColor Green
        Write-Log "[SUCCESS] Disk Cleanup completed"
    } catch {
        Write-Host "[ERROR] Failed to run Disk Cleanup: $_" -ForegroundColor Red
        Write-Log "[ERROR] Failed to run Disk Cleanup: $_"
    }
}

# Configure Disk Cleanup recommended categories for cleanmgr /sagerun profiles
function Set-DiskCleanupRecommendations {
    param(
        [int]$SageProfile = 1,
        [switch]$Aggressive
    )
    try {
        Write-Host "Configuring Disk Cleanup profile $SageProfile..." -ForegroundColor Cyan
        Write-Log "Configuring Disk Cleanup profile $SageProfile"

        if (-not (Test-IsAdministrator)) {
            Write-Host "[WARN] Admin required to set CleanMgr categories under HKLM. Attempting anyway..." -ForegroundColor Yellow
            Write-Log "[WARN] Not running as admin; CleanMgr profile write may fail"
        }

        $root = "HKEY_LOCAL_MACHINE"
        $basePath = "SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches"
        $flagName = ('StateFlags{0:0000}' -f $SageProfile)

        # Baseline recommended categories
        $keys = @(
            'Active Setup Temp Folders',
            'Delivery Optimization Files',
            'Device Driver Packages',
            'Downloaded Program Files',
            'Internet Cache Files',
            'Language Pack',
            'Old ChkDsk Files',
            'Previous Installations',
            'Recycle Bin',
            'RetailDemo Offline Content',
            'Service Pack Cleanup',
            'Setup Log Files',
            'System error memory dump files',
            'System error minidump files',
            'Temporary Files',
            'Temporary Setup Files',
            'Thumbnail Cache',
            'Update Cleanup',
            'Windows Defender',
            'Windows Error Reporting Files',
            'Windows ESD installation files',
            'Windows Upgrade Log Files'
        )

        if ($Aggressive) {
            $keys += @(
                'BranchCache',
                'Delivery Optimization Files ESD',
                'D3D Shader Cache',
                'GameNewsFiles',
                'Temp Files',
                'Temporary Sync Files'
            )
        }

        foreach ($k in $keys) {
            Set-RegistryValue -Root $root -Path "$basePath\$k" -Name $flagName -Value 2
        }

        Write-Host "[SUCCESS] Disk Cleanup profile configured" -ForegroundColor Green
        Write-Log "[SUCCESS] Disk Cleanup profile configured"
    } catch {
        Write-Host "[ERROR] Failed to configure Disk Cleanup profile: $_" -ForegroundColor Red
        Write-Log "[ERROR] Failed to configure Disk Cleanup profile: $_"
    }
}

# Change Windows Terminal Default
function Set-TerminalDefault {
    Write-Host "Changing Windows Terminal default to PowerShell 7..." -ForegroundColor Cyan
    Write-Log "Changing Windows Terminal default to PowerShell 7"
    try {
        $settingsPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
        if (Test-Path $settingsPath) {
            $settings = Get-Content $settingsPath | ConvertFrom-Json
            $ps7Profile = $settings.profiles.list | Where-Object { $_.name -eq "PowerShell" -or $_.name -eq "pwsh" } | Select-Object -First 1
            if ($ps7Profile) {
                $settings.defaultProfile = $ps7Profile.guid
                $settings | ConvertTo-Json -Depth 10 | Set-Content $settingsPath
                Write-Host "[SUCCESS] Windows Terminal default changed to PowerShell 7" -ForegroundColor Green
                Write-Log "[SUCCESS] Windows Terminal default changed to PowerShell 7"
            }
        }
    } catch {
        Write-Host "[ERROR] Failed to change Terminal default: $_" -ForegroundColor Red
        Write-Log "[ERROR] Failed to change Terminal default: $_"
    }
}

# Disable PowerShell 7 Telemetry
function Disable-PS7Telemetry {
    Write-Host "Disabling PowerShell 7 Telemetry..." -ForegroundColor Cyan
    Write-Log "Disabling PowerShell 7 Telemetry"
    try {
        [System.Environment]::SetEnvironmentVariable("POWERSHELL_TELEMETRY_OPTOUT", "1", [System.EnvironmentVariableTarget]::Machine)
        Write-Host "[SUCCESS] PowerShell 7 Telemetry disabled" -ForegroundColor Green
        Write-Log "[SUCCESS] PowerShell 7 Telemetry disabled"
    } catch {
        Write-Host "[ERROR] Failed to disable PowerShell 7 Telemetry: $_" -ForegroundColor Red
        Write-Log "[ERROR] Failed to disable PowerShell 7 Telemetry: $_"
    }
}

# Disable Recall
function Disable-Recall {
    Write-Host "Disabling Recall..." -ForegroundColor Cyan
    Write-Log "Disabling Recall"
    try {
        Set-RegistryValue -Root "HKEY_CURRENT_USER" -Path "Software\Policies\Microsoft\Windows\WindowsAI" -Name "DisableAIDataAnalysis" -Value 1
        Set-RegistryValue -Root "HKEY_LOCAL_MACHINE" -Path "SOFTWARE\Policies\Microsoft\Windows\WindowsAI" -Name "DisableAIDataAnalysis" -Value 1
        Write-Host "[SUCCESS] Recall disabled" -ForegroundColor Green
        Write-Log "[SUCCESS] Recall disabled"
    } catch {
        Write-Host "[ERROR] Failed to disable Recall: $_" -ForegroundColor Red
        Write-Log "[ERROR] Failed to disable Recall: $_"
    }
}

# Set Hibernation as Default
function Set-HibernationDefault {
    Write-Host "Setting Hibernation as default..." -ForegroundColor Cyan
    Write-Log "Setting Hibernation as default"
    try {
        Invoke-ExternalCommand "powercfg.exe /hibernate on"
        Invoke-ExternalCommand "powercfg.exe /change standby-timeout-ac 0"
        Invoke-ExternalCommand "powercfg.exe /change hibernate-timeout-ac 30"
        Write-Host "[SUCCESS] Hibernation set as default" -ForegroundColor Green
        Write-Log "[SUCCESS] Hibernation set as default"
    } catch {
        Write-Host "[ERROR] Failed to set Hibernation as default: $_" -ForegroundColor Red
        Write-Log "[ERROR] Failed to set Hibernation as default: $_"
    }
}

## Removed: Set-ServicesManual (unused)

# Debloat Brave
function Optimize-Brave {
    Write-Host "Debloating Brave..." -ForegroundColor Cyan
    Write-Log "Debloating Brave"
    try {
        $bravePath = "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data\Default\Preferences"
        if (Test-Path $bravePath) {
            $prefs = Get-Content $bravePath | ConvertFrom-Json
            $prefs.profile.default_content_setting_values.notifications = 2
            $prefs | ConvertTo-Json -Depth 10 | Set-Content $bravePath
        }
        Write-Host "[SUCCESS] Brave debloated" -ForegroundColor Green
        Write-Log "[SUCCESS] Brave debloated"
    } catch {
        Write-Host "[ERROR] Failed to debloat Brave: $_" -ForegroundColor Red
        Write-Log "[ERROR] Failed to debloat Brave: $_"
    }
}

# Debloat Edge
function Optimize-Edge {
    Write-Host "Debloating Edge..." -ForegroundColor Cyan
    Write-Log "Debloating Edge"
    try {
        Set-RegistryValue -Root "HKEY_LOCAL_MACHINE" -Path "SOFTWARE\Policies\Microsoft\Edge" -Name "HideFirstRunExperience" -Value 1
        Set-RegistryValue -Root "HKEY_LOCAL_MACHINE" -Path "SOFTWARE\Policies\Microsoft\Edge" -Name "ComponentUpdatesEnabled" -Value 0
        Write-Host "[SUCCESS] Edge debloated" -ForegroundColor Green
        Write-Log "[SUCCESS] Edge debloated"
    } catch {
        Write-Host "[ERROR] Failed to debloat Edge: $_" -ForegroundColor Red
        Write-Log "[ERROR] Failed to debloat Edge: $_"
    }
}

# ===============================================================================================================================
#                                                           PREFERENCES
# ===============================================================================================================================
# Helper function to get current preference state
function Get-PreferenceState {
    param([string]$PreferenceName)
    
    try {
        switch ($PreferenceName) {
            "DarkTheme" {
                $value = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "AppsUseLightTheme" -ErrorAction Stop
                return ($value.AppsUseLightTheme -eq 0)
            }
            "BingSearch" {
                $value = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "BingSearchEnabled" -ErrorAction SilentlyContinue
                return ($value.BingSearchEnabled -eq 1)
            }
            "NumLock" {
                $value = Get-ItemProperty -Path "HKU:\.DEFAULT\Control Panel\Keyboard" -Name "InitialKeyboardIndicators" -ErrorAction SilentlyContinue
                return ($value.InitialKeyboardIndicators -eq "2")
            }
            "VerboseLogon" {
                $value = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "VerboseStatus" -ErrorAction SilentlyContinue
                return ($value.VerboseStatus -eq 1)
            }
            "StartRecommendations" {
                $value = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Start_IrisRecommendations" -ErrorAction SilentlyContinue
                return ($value.Start_IrisRecommendations -eq 1)
            }
            "SettingsHomePage" {
                $value = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Settings" -Name "EnableHomePage" -ErrorAction SilentlyContinue
                return ($value.EnableHomePage -eq 1)
            }
            "SnapWindow" {
                $value = Get-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "WindowArrangementActive" -ErrorAction SilentlyContinue
                return ($value.WindowArrangementActive -eq "1")
            }
            "SnapAssistFlyout" {
                $value = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "SnapAssist" -ErrorAction SilentlyContinue
                return ($value.SnapAssist -eq 1)
            }
            "SnapAssistSuggestion" {
                $value = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "SnapFill" -ErrorAction SilentlyContinue
                return ($value.SnapFill -eq 1)
            }
            "MouseAcceleration" {
                $value = Get-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseSpeed" -ErrorAction Stop
                return ($value.MouseSpeed -ne "0")
            }
            "StickyKeys" {
                $value = Get-ItemProperty -Path "HKCU:\Control Panel\Accessibility\StickyKeys" -Name "Flags" -ErrorAction SilentlyContinue
                return ($value.Flags -eq "510")
            }
            "ShowHiddenFiles" {
                $value = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Hidden" -ErrorAction Stop
                return ($value.Hidden -eq 1)
            }
            "ShowFileExtensions" {
                $value = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -ErrorAction Stop
                return ($value.HideFileExt -eq 0)
            }
            "DesktopIcons" {
                $value = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideIcons" -ErrorAction SilentlyContinue
                # Return true when icons are visible (HideIcons = 0)
                return ($value.HideIcons -eq 0)
            }
            "SearchButton" {
                $value = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "SearchboxTaskbarMode" -ErrorAction SilentlyContinue
                return ($value.SearchboxTaskbarMode -ne 0)
            }
            "TaskViewButton" {
                $value = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowTaskViewButton" -ErrorAction SilentlyContinue
                return ($value.ShowTaskViewButton -eq 1)
            }
            "CenterTaskbar" {
                $value = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarAl" -ErrorAction SilentlyContinue
                return ($value.TaskbarAl -eq 1)
            }
            "WidgetsButton" {
                $value = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarDa" -ErrorAction SilentlyContinue
                return ($value.TaskbarDa -eq 1)
            }
            "DetailedBSoD" {
                $value = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl" -Name "DisplayParameters" -ErrorAction SilentlyContinue
                return ($value.DisplayParameters -eq 1)
            }
            "S3Sleep" {
                $value = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power" -Name "PlatformAoAcOverride" -ErrorAction SilentlyContinue
                return ($value.PlatformAoAcOverride -eq 0)
            }
            default { return $false }
        }
    } catch {
        return $false
    }
}

# Preference: Dark Theme for Windows
function Set-DarkTheme {
    param([bool]$Enable)
    try {
        $value = if ($Enable) { 0 } else { 1 }
    Set-RegistryValue -Root "HKEY_CURRENT_USER" -Path "Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "AppsUseLightTheme" -Value $value
    Set-RegistryValue -Root "HKEY_CURRENT_USER" -Path "Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "SystemUsesLightTheme" -Value $value
        Write-Host "[SUCCESS] Dark Theme $(if($Enable){'enabled'}else{'disabled'})" -ForegroundColor Green
        Write-Log "Dark Theme $(if($Enable){'ENABLED'}else{'DISABLED'})"
    } catch {
        Write-Host "[ERROR] Failed to set Dark Theme: $_" -ForegroundColor Red
        Write-Log "[ERROR] Failed to set Dark Theme: $_"
    }
}

# Preference: Bing Search in Start Menu
function Set-BingSearch {
    param([bool]$Enable)
    try {
        $value = if ($Enable) { 1 } else { 0 }
    Set-RegistryValue -Root "HKEY_CURRENT_USER" -Path "Software\Microsoft\Windows\CurrentVersion\Search" -Name "BingSearchEnabled" -Value $value
        Write-Host "[SUCCESS] Bing Search $(if($Enable){'enabled'}else{'disabled'})" -ForegroundColor Green
        Write-Log "Bing Search $(if($Enable){'ENABLED'}else{'DISABLED'})"
    } catch {
        Write-Host "[ERROR] Failed to set Bing Search: $_" -ForegroundColor Red
        Write-Log "[ERROR] Failed to set Bing Search: $_"
    }
}

# Preference: NumLock on Startup
function Set-NumLockStartup {
    param([bool]$Enable)
    try {
        $value = if ($Enable) { "2" } else { "0" }
    New-PSDrive -PSProvider Registry -Name HKU -Root HKEY_USERS -ErrorAction SilentlyContinue | Out-Null
    Set-ItemProperty -Path "HKU:\.DEFAULT\Control Panel\Keyboard" -Name "InitialKeyboardIndicators" -Value $value -Force
        Write-Host "[SUCCESS] NumLock on Startup $(if($Enable){'enabled'}else{'disabled'})" -ForegroundColor Green
        Write-Log "NumLock on Startup $(if($Enable){'ENABLED'}else{'DISABLED'})"
    } catch {
        Write-Host "[ERROR] Failed to set NumLock on Startup: $_" -ForegroundColor Red
        Write-Log "[ERROR] Failed to set NumLock on Startup: $_"
    }
}

# Preference: Verbose Messages During Logon
function Set-VerboseLogon {
    param([bool]$Enable)
    try {
        $value = if ($Enable) { 1 } else { 0 }
    Set-RegistryValue -Root "HKEY_LOCAL_MACHINE" -Path "SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "VerboseStatus" -Value $value
        Write-Host "[SUCCESS] Verbose Logon $(if($Enable){'enabled'}else{'disabled'})" -ForegroundColor Green
        Write-Log "Verbose Logon $(if($Enable){'ENABLED'}else{'DISABLED'})"
    } catch {
        Write-Host "[ERROR] Failed to set Verbose Logon: $_" -ForegroundColor Red
        Write-Log "[ERROR] Failed to set Verbose Logon: $_"
    }
}

# Preference: Recommendations in Start Menu
function Set-StartRecommendations {
    param([bool]$Enable)
    try {
        $value = if ($Enable) { 1 } else { 0 }
    Set-RegistryValue -Root "HKEY_CURRENT_USER" -Path "Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Start_IrisRecommendations" -Value $value
        Write-Host "[SUCCESS] Start Recommendations $(if($Enable){'enabled'}else{'disabled'})" -ForegroundColor Green
        Write-Log "Start Recommendations $(if($Enable){'ENABLED'}else{'DISABLED'})"
    } catch {
        Write-Host "[ERROR] Failed to set Start Recommendations: $_" -ForegroundColor Red
        Write-Log "[ERROR] Failed to set Start Recommendations: $_"
    }
}

# Preference: Remove Settings Home Page
function Set-SettingsHomePage {
    param([bool]$Enable)
    try {
        $value = if ($Enable) { 1 } else { 0 }
    Set-RegistryValue -Root "HKEY_CURRENT_USER" -Path "Software\Microsoft\Windows\CurrentVersion\Settings" -Name "EnableHomePage" -Value $value
        Write-Host "[SUCCESS] Settings Home Page $(if($Enable){'enabled'}else{'disabled'})" -ForegroundColor Green
        Write-Log "Settings Home Page $(if($Enable){'ENABLED'}else{'DISABLED'})"
    } catch {
        Write-Host "[ERROR] Failed to set Settings Home Page: $_" -ForegroundColor Red
        Write-Log "[ERROR] Failed to set Settings Home Page: $_"
    }
}

# Preference: Snap Window
function Set-SnapWindow {
    param([bool]$Enable)
    try {
        $value = if ($Enable) { "1" } else { "0" }
    Set-RegistryValue -Root "HKEY_CURRENT_USER" -Path "Control Panel\Desktop" -Name "WindowArrangementActive" -Value $value -ValueType ([Microsoft.Win32.RegistryValueKind]::String)
        Write-Host "[SUCCESS] Snap Window $(if($Enable){'enabled'}else{'disabled'})" -ForegroundColor Green
        Write-Log "Snap Window $(if($Enable){'ENABLED'}else{'DISABLED'})"
        Restart-Explorer
    } catch {
        Write-Host "[ERROR] Failed to set Snap Window: $_" -ForegroundColor Red
        Write-Log "[ERROR] Failed to set Snap Window: $_"
    }
}

# Preference: Snap Assist Flyout
function Set-SnapAssistFlyout {
    param([bool]$Enable)
    try {
        $value = if ($Enable) { 1 } else { 0 }
    Set-RegistryValue -Root "HKEY_CURRENT_USER" -Path "Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "SnapAssist" -Value $value
        Write-Host "[SUCCESS] Snap Assist Flyout $(if($Enable){'enabled'}else{'disabled'})" -ForegroundColor Green
        Write-Log "Snap Assist Flyout $(if($Enable){'ENABLED'}else{'DISABLED'})"
        Restart-Explorer
    } catch {
        Write-Host "[ERROR] Failed to set Snap Assist Flyout: $_" -ForegroundColor Red
        Write-Log "[ERROR] Failed to set Snap Assist Flyout: $_"
    }
}

# Preference: Snap Assist Suggestion
function Set-SnapAssistSuggestion {
    param([bool]$Enable)
    try {
        $value = if ($Enable) { 1 } else { 0 }
    Set-RegistryValue -Root "HKEY_CURRENT_USER" -Path "Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "SnapFill" -Value $value
        Write-Host "[SUCCESS] Snap Assist Suggestion $(if($Enable){'enabled'}else{'disabled'})" -ForegroundColor Green
        Write-Log "Snap Assist Suggestion $(if($Enable){'ENABLED'}else{'DISABLED'})"
        Restart-Explorer
    } catch {
        Write-Host "[ERROR] Failed to set Snap Assist Suggestion: $_" -ForegroundColor Red
        Write-Log "[ERROR] Failed to set Snap Assist Suggestion: $_"
    }
}

# Preference: Mouse Acceleration
function Set-MouseAcceleration {
    param([bool]$Enable)
    try {
        if ($Enable) {
            Set-RegistryValue -Root "HKEY_CURRENT_USER" -Path "Control Panel\Mouse" -Name "MouseSpeed" -Value 1 -ValueType ([Microsoft.Win32.RegistryValueKind]::String)
            Set-RegistryValue -Root "HKEY_CURRENT_USER" -Path "Control Panel\Mouse" -Name "MouseThreshold1" -Value 6 -ValueType ([Microsoft.Win32.RegistryValueKind]::String)
            Set-RegistryValue -Root "HKEY_CURRENT_USER" -Path "Control Panel\Mouse" -Name "MouseThreshold2" -Value 10 -ValueType ([Microsoft.Win32.RegistryValueKind]::String)
            Write-Host "[SUCCESS] Mouse Acceleration enabled" -ForegroundColor Green
            Write-Log "Mouse Acceleration ENABLED"
        } else {
            Set-RegistryValue -Root "HKEY_CURRENT_USER" -Path "Control Panel\Mouse" -Name "MouseSpeed" -Value 0 -ValueType ([Microsoft.Win32.RegistryValueKind]::String)
            Set-RegistryValue -Root "HKEY_CURRENT_USER" -Path "Control Panel\Mouse" -Name "MouseThreshold1" -Value 0 -ValueType ([Microsoft.Win32.RegistryValueKind]::String)
            Set-RegistryValue -Root "HKEY_CURRENT_USER" -Path "Control Panel\Mouse" -Name "MouseThreshold2" -Value 0 -ValueType ([Microsoft.Win32.RegistryValueKind]::String)
            Write-Host "[SUCCESS] Mouse Acceleration disabled" -ForegroundColor Green
            Write-Log "Mouse Acceleration DISABLED"
        }
    Invoke-MouseSettingsLive
    } catch {
        Write-Host "[ERROR] Failed to set Mouse Acceleration: $_" -ForegroundColor Red
        Write-Log "[ERROR] Failed to set Mouse Acceleration: $_"
    }
}

# Preference: Sticky Keys
function Set-StickyKeys {
    param([bool]$Enable)
    try {
        $value = if ($Enable) { "510" } else { "506" }
    Set-RegistryValue -Root "HKEY_CURRENT_USER" -Path "Control Panel\Accessibility\StickyKeys" -Name "Flags" -Value $value -ValueType ([Microsoft.Win32.RegistryValueKind]::String)
        Write-Host "[SUCCESS] Sticky Keys $(if($Enable){'enabled'}else{'disabled'})" -ForegroundColor Green
        Write-Log "Sticky Keys $(if($Enable){'ENABLED'}else{'DISABLED'})"
    } catch {
        Write-Host "[ERROR] Failed to set Sticky Keys: $_" -ForegroundColor Red
        Write-Log "[ERROR] Failed to set Sticky Keys: $_"
    }
}

function Restart-Explorer {
    try {
        Write-Log "Restarting Windows Explorer to apply view changes..."
        $running = Get-Process -Name explorer -ErrorAction SilentlyContinue
        if ($running) {
            # Ask Explorer to restart itself. This avoids spawning a folder window.
            Start-Process -FilePath explorer.exe -ArgumentList '/restart' -WindowStyle Hidden | Out-Null
        } else {
            # If Explorer isn't running, start the shell. Using no arguments reduces the chance of extra windows.
            Start-Process -FilePath explorer.exe | Out-Null
        }
        Start-Sleep -Milliseconds 500
        Write-Log "Windows Explorer restarted."
    } catch {
        Write-Log "[ERROR] Failed to restart Windows Explorer: $_"
    }
}

# Broadcast a system setting change (e.g., Control Panel sections)
function Invoke-SettingChangeBroadcast {
    param(
        [Parameter(Mandatory)] [string]$Section
    )
    try {
        if (-not ([System.Management.Automation.PSTypeName] 'NativeMethods').Type) {
            Add-Type -Language CSharp @"
using System;
using System.Runtime.InteropServices;
public static class NativeMethods {
    public static readonly IntPtr HWND_BROADCAST = new IntPtr(0xFFFF);
    public const int WM_SETTINGCHANGE = 0x001A;
    [DllImport("user32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    public static extern IntPtr SendMessageTimeout(IntPtr hWnd, uint Msg, UIntPtr wParam, string lParam, uint fuFlags, uint uTimeout, out UIntPtr lpdwResult);
}
"@
        }
        [UIntPtr]$result = [UIntPtr]::Zero
        # SMTO_NORMAL=0, timeout 250ms is enough
        [void][NativeMethods]::SendMessageTimeout([NativeMethods]::HWND_BROADCAST, [uint32][NativeMethods]::WM_SETTINGCHANGE, [UIntPtr]::Zero, $Section, 0u, 250u, [ref]$result)
        Write-Log "Broadcasted WM_SETTINGCHANGE for '$Section'"
    } catch {
        Write-Log "[ERROR] Failed to broadcast setting change for '$Section': $_"
    }
}

# Apply mouse registry changes immediately
function Invoke-MouseSettingsLive {
    try {
    Invoke-SettingChangeBroadcast -Section "Control Panel\\Mouse"
        Write-Log "Mouse settings applied live"
    } catch {
        Write-Log "[ERROR] Failed to apply mouse settings live: $_"
    }
}

# Preference: Show Hidden Files
function Set-ShowHiddenFiles {
    param([bool]$Enable)
    try {
        $value = if ($Enable) { 1 } else { 2 }
        Set-RegistryValue -Root "HKEY_CURRENT_USER" -Path "Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Hidden" -Value $value
        Write-Host "[SUCCESS] Show Hidden Files $(if($Enable){'enabled'}else{'disabled'})" -ForegroundColor Green
        Write-Log "Show Hidden Files $(if($Enable){'ENABLED'}else{'DISABLED'})"
        Restart-Explorer
    } catch {
        Write-Host "[ERROR] Failed to set Show Hidden Files: $_" -ForegroundColor Red
        Write-Log "[ERROR] Failed to set Show Hidden Files: $_"
    }
}

# Preference: Show File Extensions
function Set-ShowFileExtensions {
    param([bool]$Enable)
    try {
        $value = if ($Enable) { 0 } else { 1 }
        Set-RegistryValue -Root "HKEY_CURRENT_USER" -Path "Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Value $value
        Write-Host "[SUCCESS] Show File Extensions $(if($Enable){'enabled'}else{'disabled'})" -ForegroundColor Green
        Write-Log "Show File Extensions $(if($Enable){'ENABLED'}else{'DISABLED'})"
        Restart-Explorer
    } catch {
        Write-Host "[ERROR] Failed to set Show File Extensions: $_" -ForegroundColor Red
        Write-Log "[ERROR] Failed to set Show File Extensions: $_"
    }
}

# Preference: Show Desktop Icons
function Set-DesktopIconsVisible {
    param([bool]$Enable)
    try {
        # HideIcons: 0 = show icons, 1 = hide icons
        $value = if ($Enable) { 0 } else { 1 }
        $ok = Set-RegistryValue -Root "HKEY_CURRENT_USER" -Path "Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideIcons" -Value $value
        if (-not $ok) { throw "Failed to write HideIcons" }

        # Notify Explorer of setting change; this often applies without a full restart
        Invoke-SettingChangeBroadcast -Section "Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Advanced"
        Start-Sleep -Milliseconds 200

        # Verify; if not applied, restart Explorer quietly as fallback
        $applied = Get-PreferenceState "DesktopIcons"
        if ($applied -ne $Enable) {
            Restart-Explorer
            Start-Sleep -Milliseconds 500
        }
        Write-Host "[SUCCESS] Desktop Icons $(if($Enable){'shown'}else{'hidden'})" -ForegroundColor Green
        Write-Log "Desktop Icons $(if($Enable){'SHOWN'}else{'HIDDEN'})"
    } catch {
        Write-Host "[ERROR] Failed to set Desktop Icons visibility: $_" -ForegroundColor Red
        Write-Log "[ERROR] Failed to set Desktop Icons visibility: $_"
    }
}

# Preference: Search Button in Taskbar
function Set-SearchButton {
    param([bool]$Enable)
    try {
        $value = if ($Enable) { 1 } else { 0 }
    Set-RegistryValue -Root "HKEY_CURRENT_USER" -Path "Software\Microsoft\Windows\CurrentVersion\Search" -Name "SearchboxTaskbarMode" -Value $value
        Write-Host "[SUCCESS] Search Button $(if($Enable){'enabled'}else{'disabled'})" -ForegroundColor Green
        Write-Log "Search Button $(if($Enable){'ENABLED'}else{'DISABLED'})"
        Restart-Explorer
    } catch {
        Write-Host "[ERROR] Failed to set Search Button: $_" -ForegroundColor Red
        Write-Log "[ERROR] Failed to set Search Button: $_"
    }
}

# Preference: Task View Button in Taskbar
function Set-TaskViewButton {
    param([bool]$Enable)
    try {
        $value = if ($Enable) { 1 } else { 0 }
    Set-RegistryValue -Root "HKEY_CURRENT_USER" -Path "Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowTaskViewButton" -Value $value
        Write-Host "[SUCCESS] Task View Button $(if($Enable){'enabled'}else{'disabled'})" -ForegroundColor Green
        Write-Log "Task View Button $(if($Enable){'ENABLED'}else{'DISABLED'})"
        Restart-Explorer
    } catch {
        Write-Host "[ERROR] Failed to set Task View Button: $_" -ForegroundColor Red
        Write-Log "[ERROR] Failed to set Task View Button: $_"
    }
}

# Preference: Center Taskbar Items
function Set-CenterTaskbar {
    param([bool]$Enable)
    try {
        $value = if ($Enable) { 1 } else { 0 }
    Set-RegistryValue -Root "HKEY_CURRENT_USER" -Path "Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarAl" -Value $value
        Write-Host "[SUCCESS] Center Taskbar $(if($Enable){'enabled'}else{'disabled'})" -ForegroundColor Green
        Write-Log "Center Taskbar $(if($Enable){'ENABLED'}else{'DISABLED'})"
    } catch {
        Write-Host "[ERROR] Failed to set Center Taskbar: $_" -ForegroundColor Red
        Write-Log "[ERROR] Failed to set Center Taskbar: $_"
    }
}

# Preference: Widgets Button in Taskbar
function Set-WidgetsButton {
    param([bool]$Enable)
    try {
        $value = if ($Enable) { 1 } else { 0 }
    Set-RegistryValue -Root "HKEY_CURRENT_USER" -Path "Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarDa" -Value $value
        Write-Host "[SUCCESS] Widgets Button $(if($Enable){'enabled'}else{'disabled'})" -ForegroundColor Green
        Write-Log "Widgets Button $(if($Enable){'ENABLED'}else{'DISABLED'})"
    } catch {
        Write-Host "[ERROR] Failed to set Widgets Button: $_" -ForegroundColor Red
        Write-Log "[ERROR] Failed to set Widgets Button: $_"
    }
}

# Preference: Detailed BSoD
function Set-DetailedBSoD {
    param([bool]$Enable)
    try {
        $value = if ($Enable) { 1 } else { 0 }
    Set-RegistryValue -Root "HKEY_LOCAL_MACHINE" -Path "SYSTEM\CurrentControlSet\Control\CrashControl" -Name "DisplayParameters" -Value $value
        Write-Host "[SUCCESS] Detailed BSoD $(if($Enable){'enabled'}else{'disabled'})" -ForegroundColor Green
        Write-Log "Detailed BSoD $(if($Enable){'ENABLED'}else{'DISABLED'})"
    } catch {
        Write-Host "[ERROR] Failed to set Detailed BSoD: $_" -ForegroundColor Red
        Write-Log "[ERROR] Failed to set Detailed BSoD: $_"
    }
}

# Preference: S3 Sleep
function Set-S3Sleep {
    param([bool]$Enable)
    try {
        $value = if ($Enable) { 0 } else { 1 }
    Set-RegistryValue -Root "HKEY_LOCAL_MACHINE" -Path "SYSTEM\CurrentControlSet\Control\Power" -Name "PlatformAoAcOverride" -Value $value
        Write-Host "[SUCCESS] S3 Sleep $(if($Enable){'enabled'}else{'disabled'})" -ForegroundColor Green
        Write-Log "S3 Sleep $(if($Enable){'ENABLED'}else{'DISABLED'})"
    } catch {
        Write-Host "[ERROR] Failed to set S3 Sleep: $_" -ForegroundColor Red
        Write-Log "[ERROR] Failed to set S3 Sleep: $_"
    }
}



# ===============================================================================================================================
#                                                           REGISTRY TWEAKS
# ===============================================================================================================================
function Get-RegistryBaseKey {
    param([Parameter(Mandatory)][string]$Root)
    switch -Regex ($Root) {
        '^(HKEY_CURRENT_USER|HKCU)$'       { return [Microsoft.Win32.Registry]::CurrentUser }
        '^(HKEY_LOCAL_MACHINE|HKLM)$'      { return [Microsoft.Win32.Registry]::LocalMachine }
        '^(HKEY_CLASSES_ROOT|HKCR)$'       { return [Microsoft.Win32.Registry]::ClassesRoot }
        '^(HKEY_USERS|HKU)$'               { return [Microsoft.Win32.Registry]::Users }
        '^(HKEY_CURRENT_CONFIG|HKCC)$'     { return [Microsoft.Win32.Registry]::CurrentConfig }
        default { throw "Unsupported registry root: $Root" }
    }
}

function New-RegistryKey {
    param(
        [Parameter(Mandatory)][string]$Root,
        [Parameter(Mandatory)][string]$Path
    )
    $base = Get-RegistryBaseKey -Root $Root
    $key = $base.OpenSubKey($Path, $true)
    if ($null -eq $key) {
        $key = $base.CreateSubKey($Path)
    }
    $key.Close()
}

function Set-RegistryValue {
    param (
        [string]$Root,
        [string]$Path,
        [string]$Name,
        [Object]$Value,
        [Microsoft.Win32.RegistryValueKind]$ValueType = [Microsoft.Win32.RegistryValueKind]::DWord
    )
    try {
        $base = Get-RegistryBaseKey -Root $Root
        $key = $base.OpenSubKey($Path, $true)
        if ($null -eq $key) { $key = $base.CreateSubKey($Path) }
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

function Invoke-ServiceTweak {
    param (
        [string]$ServiceName,
        [string]$StartupType
    )

    Write-Host "Tweaking: ${ServiceName} -> ${StartupType}" -ForegroundColor Cyan
    Write-Log "Tweaking: ${ServiceName} -> ${StartupType}"

    try {
        # Resolve actual target service names. Some services are per-user (e.g., CDPUserSvc_12345)
        $perUserBases = @('CDPUserSvc','UnistoreSvc','OneSyncSvc','PimIndexMaintenanceSvc','MessagingService')
        $targets = @()
        $svc = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
        if ($null -ne $svc) {
            $targets = @($svc.Name)
        } elseif ($perUserBases -contains $ServiceName) {
            $targets = (Get-Service -Name ("{0}*" -f $ServiceName) -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name)
        } else {
            $targets = @($ServiceName)
        }

        if (-not $targets -or $targets.Count -eq 0) {
            # Service not found on this system – log as skip
            Write-Host "[SKIP] ${ServiceName}: service not found on this system" -ForegroundColor Yellow
            Write-Log "[SKIP] ${ServiceName}: service not found on this system"
            return
        }

        foreach ($t in $targets) {
            $null = sc.exe config $t "start=$StartupType" 2>&1
            switch ($LASTEXITCODE) {
                0     { Write-Host "[OK] $($t): set startup to '$StartupType'" -ForegroundColor Green; Write-Log "[OK] $($t): set startup to '$StartupType'" }
                5     { Write-Host "[SKIP] $($t): Access denied (run as Administrator)" -ForegroundColor Yellow; Write-Log "[SKIP] $($t): Access denied (run as Administrator)" }
                1060  { Write-Host "[SKIP] $($t): service does not exist (Windows edition/feature dependent)" -ForegroundColor Yellow; Write-Log "[SKIP] $($t): service does not exist (Windows edition/feature dependent)" }
                Default { Write-Host "[ERROR] $($t): failed (exit code: $LASTEXITCODE)" -ForegroundColor Red; Write-Log "[ERROR] $($t): failed (exit code: $LASTEXITCODE)" }
            }
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
# (Removed) Elevation relaunch prompt on startup

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

    if (-not (Test-IsAdministrator)) {
        Write-Host "[WARN] Not running as Administrator. Some service changes may be skipped due to access denied." -ForegroundColor Yellow
        Write-Log  "[WARN] Not running as Administrator. Some service changes may be skipped due to access denied."
    }
    
    foreach ($tweak in $ServiceTweaks) {
        Invoke-ServiceTweak -ServiceName $tweak.Name -StartupType $tweak.Startup
    }
    
    foreach ($xbox in $XboxServices) {
        Invoke-ServiceTweak -ServiceName $xbox.Name -StartupType $xbox.Startup
    }
    
    Write-Host "=== SERVICE TWEAKS COMPLETE ===" -ForegroundColor Green
}

# ===============================
#   PACKAGE MANAGER FUNCTIONS
# ===============================

# App Database with Winget and Chocolatey IDs
$script:AppDatabase = @{
    # Browsers
    "Brave"           = @{ Winget = "Brave.Brave"; Choco = "brave" }
    "Chrome"          = @{ Winget = "Google.Chrome"; Choco = "googlechrome" }
    "Chromium"        = @{ Winget = "Hibbiki.Chromium"; Choco = "chromium" }
    "Edge"            = @{ Winget = "Microsoft.Edge"; Choco = "microsoft-edge" }
    "Falkon"          = @{ Winget = "KDE.Falkon"; Choco = "falkon" }
    "Firefox"         = @{ Winget = "Mozilla.Firefox"; Choco = "firefox" }
    "FirefoxESR"      = @{ Winget = "Mozilla.Firefox.ESR"; Choco = "firefox-esr" }
    "Floorp"          = @{ Winget = "Ablaze.Floorp"; Choco = "floorp" }
    "LibreWolf"       = @{ Winget = "LibreWolf.LibreWolf"; Choco = "librewolf" }
    "MullvadBrowser"  = @{ Winget = "MullvadVPN.MullvadBrowser"; Choco = "mullvad-browser" }
    "PaleMoon"        = @{ Winget = "MoonchildProductions.PaleMoon"; Choco = "palemoon" }
    "Thorium"         = @{ Winget = "Alex313031.Thorium.AVX2"; Choco = "thorium" }
    "TorBrowser"      = @{ Winget = "TorProject.TorBrowser"; Choco = "tor-browser" }
    "Ungoogled"       = @{ Winget = "eloston.ungoogled-chromium"; Choco = "ungoogled-chromium" }
    "Vivaldi"         = @{ Winget = "VivaldiTechnologies.Vivaldi"; Choco = "vivaldi" }
    "Waterfox"        = @{ Winget = "Waterfox.Waterfox"; Choco = "waterfox" }
    "ZenBrowser"      = @{ Winget = "Zen-Team.Zen-Browser"; Choco = "zen-browser" }
    
    # Game Launchers
    "Steam"           = @{ Winget = "Valve.Steam"; Choco = "steam" }
    "EpicGames"       = @{ Winget = "EpicGames.EpicGamesLauncher"; Choco = "epicgameslauncher" }
    "EAApp"           = @{ Winget = "ElectronicArts.EADesktop"; Choco = "ea-app" }
    "Ubisoft"         = @{ Winget = "Ubisoft.Connect"; Choco = "ubisoft-connect" }
    "GOG"             = @{ Winget = "GOG.Galaxy"; Choco = "goggalaxy" }
    
    # Proton Apps
    "ProtonVPN"       = @{ Winget = "ProtonTechnologies.ProtonVPN"; Choco = "protonvpn" }
    "ProtonMail"      = @{ Winget = "ProtonTechnologies.ProtonMailBridge"; Choco = "protonmail-bridge" }
    "ProtonDrive"     = @{ Winget = "ProtonTechnologies.ProtonDrive"; Choco = "protondrive" }
    "ProtonPass"      = @{ Winget = "ProtonTechnologies.ProtonPass"; Choco = "" } # Not available on Chocolatey
    
    # Development Tools
    "Aegisub"         = @{ Winget = "Aegisub.Aegisub"; Choco = "aegisub" }
    "Anaconda"        = @{ Winget = "Anaconda.Anaconda3"; Choco = "anaconda3" }
    "Clink"           = @{ Winget = "chrisant996.Clink"; Choco = "clink" }
    "CMake"           = @{ Winget = "Kitware.CMake"; Choco = "cmake" }
    "DaxStudio"       = @{ Winget = "DaxStudio.DaxStudio"; Choco = "daxstudio" }
    "Docker"          = @{ Winget = "Docker.DockerDesktop"; Choco = "docker-desktop" }
    "FNM"             = @{ Winget = "Schniz.fnm"; Choco = "fnm" }
    "Fork"            = @{ Winget = "Fork.Fork"; Choco = "git-fork" }
    "Git"             = @{ Winget = "Git.Git"; Choco = "git" }
    "GitButler"       = @{ Winget = "GitButler.GitButler"; Choco = "gitbutler" }
    "GitExtensions"   = @{ Winget = "GitExtensionsApp.GitExtensions"; Choco = "gitextensions" }
    "GitHubCLI"       = @{ Winget = "GitHub.cli"; Choco = "gh" }
    "GitHubDesktop"   = @{ Winget = "GitHub.GitHubDesktop"; Choco = "github-desktop" }
    "Gitify"          = @{ Winget = "Gitify.Gitify"; Choco = "gitify" }
    "GitKraken"       = @{ Winget = "Axosoft.GitKraken"; Choco = "gitkraken" }
    "Godot"           = @{ Winget = "GodotEngine.GodotEngine"; Choco = "godot" }
    "Go"              = @{ Winget = "GoLang.Go"; Choco = "golang" }
    "Helix"           = @{ Winget = "Helix.Helix"; Choco = "helix" }
    "Corretto11"      = @{ Winget = "Amazon.Corretto.11"; Choco = "corretto11jdk" }
    "Corretto17"      = @{ Winget = "Amazon.Corretto.17"; Choco = "corretto17jdk" }
    "Corretto21"      = @{ Winget = "Amazon.Corretto.21"; Choco = "corretto21jdk" }
    "Corretto8"       = @{ Winget = "Amazon.Corretto.8"; Choco = "corretto8jdk" }
    "JetbrainsToolbox" = @{ Winget = "JetBrains.Toolbox"; Choco = "jetbrainstoolbox" }
    "Lazygit"         = @{ Winget = "JesseDuffield.lazygit"; Choco = "lazygit" }
    "Miniconda"       = @{ Winget = "Anaconda.Miniconda3"; Choco = "miniconda3" }
    "Mu"              = @{ Winget = "Mu.Mu"; Choco = "mu-editor" }
    "Neovim"          = @{ Winget = "Neovim.Neovim"; Choco = "neovim" }
    "NodeJS"          = @{ Winget = "OpenJS.NodeJS"; Choco = "nodejs" }
    "NodeJSLTS"       = @{ Winget = "OpenJS.NodeJS.LTS"; Choco = "nodejs-lts" }
    "NVM"             = @{ Winget = "CoreyButler.NVMforWindows"; Choco = "nvm" }
    "Pixi"            = @{ Winget = "prefix-dev.pixi"; Choco = "pixi" }
    "OhMyPosh"        = @{ Winget = "JanDeDobbeleer.OhMyPosh"; Choco = "oh-my-posh" }
    "Postman"         = @{ Winget = "Postman.Postman"; Choco = "postman" }
    "Pulsar"          = @{ Winget = "Pulsar-Edit.Pulsar"; Choco = "pulsar" }
    "Pyenv"           = @{ Winget = "pyenv-win.pyenv-win"; Choco = "pyenv-win" }
    "Python"          = @{ Winget = "Python.Python.3.12"; Choco = "python" }
    "Rust"            = @{ Winget = "Rustlang.Rust.MSVC"; Choco = "rust" }
    "Starship"        = @{ Winget = "Starship.Starship"; Choco = "starship" }
    "SublimeMerge"    = @{ Winget = "SublimeHQ.SublimeMerge"; Choco = "sublimemerge" }
    "SublimeText"     = @{ Winget = "SublimeHQ.SublimeText.4"; Choco = "sublimetext4" }
    "Swift"           = @{ Winget = "Swift.Toolchain"; Choco = "swift" }
    "Temurin"         = @{ Winget = "EclipseAdoptium.Temurin.21.JDK"; Choco = "temurin" }
    "Thonny"          = @{ Winget = "AivarAnnamaa.Thonny"; Choco = "thonny" }
    "Unity"           = @{ Winget = "Unity.UnityHub"; Choco = "unity-hub" }
    "Vagrant"         = @{ Winget = "Hashicorp.Vagrant"; Choco = "vagrant" }
    "VisualStudio2022" = @{ Winget = "Microsoft.VisualStudio.2022.Community"; Choco = "visualstudio2022community" }
    "VSCode"          = @{ Winget = "Microsoft.VisualStudioCode"; Choco = "vscode" }
    "VSCodium"        = @{ Winget = "VSCodium.VSCodium"; Choco = "vscodium" }
    "Wezterm"         = @{ Winget = "wez.wezterm"; Choco = "wezterm" }
    "Yarn"            = @{ Winget = "Yarn.Yarn"; Choco = "yarn" }
    
    # Media & Communication
    "Discord"         = @{ Winget = "Discord.Discord"; Choco = "discord" }
    "Spotify"         = @{ Winget = "Spotify.Spotify"; Choco = "spotify" }
    "VLC"             = @{ Winget = "VideoLAN.VLC"; Choco = "vlc" }
    
    # Utilities
    "7Zip"            = @{ Winget = "7zip.7zip"; Choco = "7zip" }
    "NotepadPlusPlus" = @{ Winget = "Notepad++.Notepad++"; Choco = "notepadplusplus" }
    "OBS"             = @{ Winget = "OBSProject.OBSStudio"; Choco = "obs-studio" }
}

# Test if package manager is available
function Test-PackageManager {
    param([string]$Manager)
    
    try {
        if ($Manager -eq "Winget") {
            $result = winget --version 2>$null
            return $null -ne $result
        } elseif ($Manager -eq "Chocolatey") {
            $result = choco --version 2>$null
            return $null -ne $result
        }
    } catch {
        return $false
    }
    return $false
}

# Get installed applications
function Get-InstalledApplications {
    param([string]$Manager)
    
    $installedApps = @{}
    
    try {
        if ($Manager -eq "Winget") {
            Write-Host "Checking installed apps with Winget..." -ForegroundColor Yellow
            $wingetList = winget list --accept-source-agreements 2>$null | Out-String
            
            foreach ($app in $script:AppDatabase.Keys) {
                $packageId = $script:AppDatabase[$app].Winget
                if ($wingetList -match [regex]::Escape($packageId)) {
                    $installedApps[$app] = $true
                }
            }
        } elseif ($Manager -eq "Chocolatey") {
            Write-Host "Checking installed apps with Chocolatey..." -ForegroundColor Yellow
            $chocoList = choco list --local-only 2>$null | Out-String
            
            foreach ($app in $script:AppDatabase.Keys) {
                $packageId = $script:AppDatabase[$app].Choco
                if ($chocoList -match [regex]::Escape($packageId)) {
                    $installedApps[$app] = $true
                }
            }
        }
    } catch {
        Write-Host "[ERROR] Failed to get installed apps: $_" -ForegroundColor Red
    }
    
    return $installedApps
}

# Install applications
function Install-Applications {
    param(
        [string[]]$Apps,
        [string]$Manager
    )
    
    if (-not (Test-PackageManager -Manager $Manager)) {
        [System.Windows.MessageBox]::Show("$Manager is not installed or not found in PATH!", "Error", "OK", "Error")
        return
    }
    
    foreach ($app in $Apps) {
        if ($script:AppDatabase.ContainsKey($app)) {
            $packageId = if ($Manager -eq "Winget") { 
                $script:AppDatabase[$app].Winget 
            } else { 
                $script:AppDatabase[$app].Choco 
            }
            if ([string]::IsNullOrWhiteSpace($packageId)) {
                Write-Host "[SKIP] $app is not available via $Manager." -ForegroundColor Yellow
                continue
            }
            
            Write-Host "Installing $app using $Manager..." -ForegroundColor Yellow
            
            try {
                if ($Manager -eq "Winget") {
                    Invoke-ExternalCommand "winget install --id `"$packageId`" --exact --silent --accept-package-agreements --accept-source-agreements --time-limit 1800"
                } elseif ($Manager -eq "Chocolatey") {
                    Invoke-ExternalCommand "choco install `"$packageId`" -y --execution-timeout=2700"
                }
                Write-Host "[SUCCESS] $app installed" -ForegroundColor Green
            } catch {
                Write-Host "[ERROR] Failed to install $app : $_" -ForegroundColor Red
            }
        }
    }
}

# Uninstall applications
function Uninstall-Applications {
    param(
        [string[]]$Apps,
        [string]$Manager
    )
    
    if (-not (Test-PackageManager -Manager $Manager)) {
        [System.Windows.MessageBox]::Show("$Manager is not installed or not found in PATH!", "Error", "OK", "Error")
        return
    }
    
    foreach ($app in $Apps) {
        if ($script:AppDatabase.ContainsKey($app)) {
            $packageId = if ($Manager -eq "Winget") { 
                $script:AppDatabase[$app].Winget 
            } else { 
                $script:AppDatabase[$app].Choco 
            }
            if ([string]::IsNullOrWhiteSpace($packageId)) {
                Write-Host "[SKIP] $app is not available via $Manager." -ForegroundColor Yellow
                continue
            }
            
            Write-Host "Uninstalling $app using $Manager..." -ForegroundColor Yellow
            
            try {
                if ($Manager -eq "Winget") {
                    Invoke-ExternalCommand "winget uninstall --id `"$packageId`" --exact --silent --time-limit 1800"
                } elseif ($Manager -eq "Chocolatey") {
                    Invoke-ExternalCommand "choco uninstall `"$packageId`" -y --execution-timeout=2700"
                }
                Write-Host "[SUCCESS] $app uninstalled" -ForegroundColor Green
            } catch {
                Write-Host "[ERROR] Failed to uninstall $app : $_" -ForegroundColor Red
            }
        }
    }
}

# (Removed) noise.png path definition

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

    <!-- NoiseBrush removed -->

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
                                       FontSize="{TemplateBinding FontSize}"
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

        <!-- Custom ScrollBar -->
        <Style x:Key="CustomScrollBar" TargetType="ScrollBar">
            <Setter Property="Width" Value="8"/>
            <Setter Property="Background" Value="Transparent"/>
            <Setter Property="Foreground" Value="{StaticResource AccentBrush}"/>
            <Setter Property="Margin" Value="0,0,4,0"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="ScrollBar">
                        <Grid>
                            <Track Name="PART_Track" IsDirectionReversed="True">
                                <Track.Thumb>
                                    <Thumb>
                                        <Thumb.Template>
                                            <ControlTemplate>
                                                <Border Background="{TemplateBinding Foreground}"
                                                        CornerRadius="4"
                                                        Opacity="0.6">
                                                    <Border.Style>
                                                        <Style TargetType="Border">
                                                            <Style.Triggers>
                                                                <Trigger Property="IsMouseOver" Value="True">
                                                                    <Setter Property="Opacity" Value="1.0"/>
                                                                </Trigger>
                                                            </Style.Triggers>
                                                        </Style>
                                                    </Border.Style>
                                                </Border>
                                            </ControlTemplate>
                                        </Thumb.Template>
                                    </Thumb>
                                </Track.Thumb>
                            </Track>
                        </Grid>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- Custom ScrollViewer -->
        <Style x:Key="CustomScrollViewer" TargetType="ScrollViewer">
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="ScrollViewer">
                        <Grid>
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="Auto"/>
                            </Grid.ColumnDefinitions>
                            <ScrollContentPresenter Grid.Column="0" />
                            <ScrollBar Grid.Column="1"
                                       Name="PART_VerticalScrollBar"
                                       Value="{TemplateBinding VerticalOffset}"
                                       Maximum="{TemplateBinding ScrollableHeight}"
                                       ViewportSize="{TemplateBinding ViewportHeight}"
                                       Visibility="{TemplateBinding ComputedVerticalScrollBarVisibility}"
                                       Style="{StaticResource CustomScrollBar}"/>
                        </Grid>
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
                BorderThickness="{TemplateBinding BorderThickness}"
                Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter Property="Background" Value="{StaticResource BorderBrushColor}"/>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter Property="Background" Value="{StaticResource BorderBrushColor}"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
    </Window.Resources>

    <Grid>
        <!-- Main container (borderless) without noise texture -->
        <Border CornerRadius="15" Margin="5" BorderThickness="0" BorderBrush="{DynamicResource BorderBrushColor}" Name="MainBorder" Background="{DynamicResource WindowBackgroundBrush}">

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
                        <Button Name="BtnLogs"     Content="Logs"    Style="{StaticResource RoundedNavButton}"/>
                        <TextBlock Text="│" FontSize="20" Foreground="{DynamicResource ForegroundBrush}" VerticalAlignment="Center" Margin="8,0"/>
                        <Button Name="BtnActivateWindows" Style="{StaticResource RoundedNavButton}" Width="Auto">
                            <TextBlock Text="Activate Windows" Margin="14,0"/>
                        </Button>
                        <TextBlock Text="│" FontSize="20" Foreground="{DynamicResource ForegroundBrush}" VerticalAlignment="Center" Margin="8,0"/>
                        <Button Name="BtnCreateRestorePoint" Style="{StaticResource RoundedNavButton}" Width="Auto">
                            <TextBlock Text="Create Restore Point" Margin="14,0"/>
                        </Button>
                    </StackPanel>

                    <!-- Right: theme + window controls -->
                    <StackPanel Orientation="Horizontal" HorizontalAlignment="Right" VerticalAlignment="Center" Margin="15,0">
                        <Button Name="BtnToggleTheme" Content="🌙" Style="{StaticResource WindowControlButton}" ToolTip="Toggle Theme"/>
                        <Button Name="BtnMinimize" Content="-" Style="{StaticResource WindowControlButton}" ToolTip="Minimize"/>
                        <Button Name="BtnMaximize" Content="+" Style="{StaticResource WindowControlButton}" ToolTip="Maximize"/>
                        <Button Name="BtnClose" Content="X" Style="{StaticResource CloseButton}" ToolTip="Close"/>
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
                            
                            <!-- OS -->
                            <TextBlock Name="LblOS" FontSize="16" Margin="0,8" Foreground="{DynamicResource ForegroundBrush}"/>
                            
                            <!-- CPU (Always Expanded) -->
                            <TextBlock Name="LblCPU" FontSize="16" Margin="0,8" Foreground="{DynamicResource ForegroundBrush}"/>
                            <TextBlock Name="LblCPUDetails" FontSize="14" Foreground="#B0B0B0" Margin="20,4,0,8"/>
                            
                            <!-- RAM (Always Expanded) -->
                            <TextBlock Name="LblRAM" FontSize="16" Margin="0,8" Foreground="{DynamicResource ForegroundBrush}"/>
                            <TextBlock Name="LblRAMDetails" FontSize="14" Foreground="#B0B0B0" Margin="20,4,0,8"/>
                            
                            <!-- GPU (Always Expanded) -->
                            <TextBlock Name="LblGPU" FontSize="16" Margin="0,8" Foreground="{DynamicResource ForegroundBrush}"/>
                            <TextBlock Name="LblGPUDetails" FontSize="14" Foreground="#B0B0B0" Margin="20,4,0,8"/>
                            
                            <!-- Motherboard -->
                            <TextBlock Name="LblMotherboard" FontSize="16" Margin="0,8" Foreground="{DynamicResource ForegroundBrush}"/>
                            
                            <!-- BIOS -->
                            <TextBlock Name="LblBIOS" FontSize="16" Margin="0,8" Foreground="{DynamicResource ForegroundBrush}"/>
                            
                            <!-- Disks (All drives shown) -->
                            <TextBlock Text="Storage:" FontSize="16" Margin="0,8,0,4" Foreground="{DynamicResource ForegroundBrush}"/>
                            <StackPanel Name="DiskList" Margin="20,0,0,8"/>
                            
                            <!-- Network -->
                            <TextBlock Name="LblNetwork" FontSize="16" Margin="0,8" Foreground="{DynamicResource ForegroundBrush}"/>
                            
                            <!-- Sound -->
                            <TextBlock Name="LblSound" FontSize="16" Margin="0,8" Foreground="{DynamicResource ForegroundBrush}"/>
                        </StackPanel>

                        <StackPanel Grid.Column="1" Margin="30,0,0,0">
                            <!-- Advanced Info Section -->
                            <DockPanel Margin="0,0,0,20">
                                <TextBlock Text="Advanced Info" FontSize="24" FontWeight="Bold"
                                           Foreground="{DynamicResource ForegroundBrush}" VerticalAlignment="Center"/>
                                <Button Name="BtnToggleAdvanced" Content="*" Width="34" Height="34"
                                        DockPanel.Dock="Right" HorizontalAlignment="Right"
                                        Background="Transparent" BorderBrush="{DynamicResource BorderBrushColor}"
                                        BorderThickness="1"
                                        Foreground="{DynamicResource ForegroundBrush}"
                                        FontSize="18" FontWeight="Bold"/>
                            </DockPanel>
                            <Separator Background="{DynamicResource BorderBrushColor}" Height="1" Margin="0,0,0,20"/>
                            <TextBlock Name="LblRouterIP" FontSize="16" Margin="0,8" Foreground="{DynamicResource ForegroundBrush}"/>
                            <TextBlock Name="LblIP" FontSize="16" Margin="0,8" Foreground="{DynamicResource ForegroundBrush}"/>
                            <TextBlock Name="LblMAC" FontSize="16" Margin="0,8" Foreground="{DynamicResource ForegroundBrush}"/>
                            <TextBlock Name="LblHWID" FontSize="16" Margin="0,8" Foreground="{DynamicResource ForegroundBrush}"/>
                            <TextBlock Name="LblPublicIP" FontSize="16" Margin="0,8" Foreground="{DynamicResource ForegroundBrush}"/>
                            
                            <!-- Advanced PC Info Section -->
                            <DockPanel Margin="0,40,0,20">
                                <TextBlock Text="Advanced PC Info" FontSize="24" FontWeight="Bold"
                                           Foreground="{DynamicResource ForegroundBrush}" VerticalAlignment="Center"/>
                            </DockPanel>
                            <Separator Background="{DynamicResource BorderBrushColor}" Height="1" Margin="0,0,0,20"/>
                            <TextBlock Name="LblTPM" FontSize="16" Margin="0,8" Foreground="{DynamicResource ForegroundBrush}"/>
                            <TextBlock Name="LblSecureBoot" FontSize="16" Margin="0,8" Foreground="{DynamicResource ForegroundBrush}"/>
                            <TextBlock Name="LblVirtualization" FontSize="16" Margin="0,8" Foreground="{DynamicResource ForegroundBrush}"/>
                            <TextBlock Name="LblUEFI" FontSize="16" Margin="0,8" Foreground="{DynamicResource ForegroundBrush}"/>
                            <TextBlock Name="LblBitLocker" FontSize="16" Margin="0,8" Foreground="{DynamicResource ForegroundBrush}"/>
                        </StackPanel>
                    </Grid>

                    <!-- Install -->
                    <Grid Name="PageInstall" Visibility="Collapsed">
                        <Grid.RowDefinitions>
                            <RowDefinition Height="Auto"/>
                            <RowDefinition Height="Auto"/>
                            <RowDefinition Height="*"/>
                        </Grid.RowDefinitions>

                        <!-- Header -->
                        <TextBlock Grid.Row="0" Text="Install Applications" FontSize="24" FontWeight="Bold"
                                   Foreground="{DynamicResource ForegroundBrush}" Margin="0,0,0,20"/>

            <!-- Control Buttons -->
            <Border Grid.Row="1" Background="{DynamicResource CardBrush}" 
                CornerRadius="8" BorderBrush="{DynamicResource BorderBrushColor}" 
                BorderThickness="2" Padding="15" Margin="0,0,0,15"
                SnapsToDevicePixels="True" UseLayoutRounding="True">
                            <Grid>
                                <Grid.RowDefinitions>
                                    <RowDefinition Height="Auto"/>
                                    <RowDefinition Height="Auto"/>
                                </Grid.RowDefinitions>
                                
                                <!-- Top Row: Main Actions -->
                                <StackPanel Grid.Row="0" Orientation="Horizontal" HorizontalAlignment="Left" Margin="15,0,0,10">
                                    <Button Name="BtnGetInstalled" Height="38" Padding="15,0" Margin="0,0,10,0"
                                            Background="Transparent" BorderThickness="0" Cursor="Hand"
                                            Foreground="{DynamicResource ForegroundBrush}" FontSize="14">
                                        <Button.Template>
                                            <ControlTemplate TargetType="Button">
                                                <Border Background="{TemplateBinding Background}" 
                                                        CornerRadius="8" Padding="{TemplateBinding Padding}">
                                                    <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                                                </Border>
                                            </ControlTemplate>
                                        </Button.Template>
                                        <Button.Style>
                                            <Style TargetType="Button">
                                                <Setter Property="Background" Value="Transparent"/>
                                                <Style.Triggers>
                                                    <Trigger Property="IsMouseOver" Value="True">
                                                        <Setter Property="Background" Value="#40FFFFFF"/>
                                                    </Trigger>
                                                </Style.Triggers>
                                            </Style>
                                        </Button.Style>
                                        <TextBlock Text="Get Installed Apps"/>
                                    </Button>
                                    
                                    <Button Name="BtnClearSelection" Height="38" Padding="15,0" Margin="0,0,10,0"
                                            Background="Transparent" BorderThickness="0" Cursor="Hand"
                                            Foreground="{DynamicResource ForegroundBrush}" FontSize="14">
                                        <Button.Template>
                                            <ControlTemplate TargetType="Button">
                                                <Border Background="{TemplateBinding Background}" 
                                                        CornerRadius="8" Padding="{TemplateBinding Padding}">
                                                    <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                                                </Border>
                                            </ControlTemplate>
                                        </Button.Template>
                                        <Button.Style>
                                            <Style TargetType="Button">
                                                <Setter Property="Background" Value="Transparent"/>
                                                <Style.Triggers>
                                                    <Trigger Property="IsMouseOver" Value="True">
                                                        <Setter Property="Background" Value="#40FFFFFF"/>
                                                    </Trigger>
                                                </Style.Triggers>
                                            </Style>
                                        </Button.Style>
                                        <TextBlock Text="Clear Selection"/>
                                    </Button>
                                    
                                    <Button Name="BtnUninstall" Height="38" Padding="15,0" Margin="0,0,10,0"
                                            Background="Transparent" BorderThickness="0" Cursor="Hand"
                                            Foreground="{DynamicResource ForegroundBrush}" FontSize="14">
                                        <Button.Template>
                                            <ControlTemplate TargetType="Button">
                                                <Border Background="{TemplateBinding Background}" 
                                                        CornerRadius="8" Padding="{TemplateBinding Padding}">
                                                    <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                                                </Border>
                                            </ControlTemplate>
                                        </Button.Template>
                                        <Button.Style>
                                            <Style TargetType="Button">
                                                <Setter Property="Background" Value="Transparent"/>
                                                <Style.Triggers>
                                                    <Trigger Property="IsMouseOver" Value="True">
                                                        <Setter Property="Background" Value="#40FFFFFF"/>
                                                    </Trigger>
                                                </Style.Triggers>
                                            </Style>
                                        </Button.Style>
                                        <TextBlock Text="Uninstall Selected"/>
                                    </Button>
                                    
                                    <Button Name="BtnInstallUpdate" Height="38" Padding="15,0"
                                            Background="Transparent" BorderThickness="0" Cursor="Hand"
                                            Foreground="{DynamicResource ForegroundBrush}" FontSize="14">
                                        <Button.Template>
                                            <ControlTemplate TargetType="Button">
                                                <Border Background="{TemplateBinding Background}" 
                                                        CornerRadius="8" Padding="{TemplateBinding Padding}">
                                                    <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                                                </Border>
                                            </ControlTemplate>
                                        </Button.Template>
                                        <Button.Style>
                                            <Style TargetType="Button">
                                                <Setter Property="Background" Value="Transparent"/>
                                                <Style.Triggers>
                                                    <Trigger Property="IsMouseOver" Value="True">
                                                        <Setter Property="Background" Value="#40FFFFFF"/>
                                                    </Trigger>
                                                </Style.Triggers>
                                            </Style>
                                        </Button.Style>
                                        <TextBlock Text="Install/Update Selected"/>
                                    </Button>
                                </StackPanel>
                                
                                <!-- Bottom Row: Package Manager Selection (left aligned with top buttons' inner padding) -->
                                <StackPanel Grid.Row="1" Orientation="Horizontal" HorizontalAlignment="Left" Margin="15,0,0,0">
                                    <TextBlock Text="Package Manager:" FontSize="14" 
                                               Foreground="{DynamicResource ForegroundBrush}" 
                                               VerticalAlignment="Center" Margin="0,0,15,0"/>
                                    <RadioButton Name="RbWinget" Content="Winget" GroupName="PackageManager" 
                                                 Foreground="{DynamicResource ForegroundBrush}" 
                                                 IsChecked="True" VerticalAlignment="Center" Margin="0,0,20,0"/>
                                    <RadioButton Name="RbChocolatey" Content="Chocolatey" GroupName="PackageManager" 
                                                 Foreground="{DynamicResource ForegroundBrush}" 
                                                 VerticalAlignment="Center"/>
                                </StackPanel>
                            </Grid>
                        </Border>

                        <!-- Apps List -->
            <Border Grid.Row="2" Background="{DynamicResource WindowBackgroundBrush}" 
                CornerRadius="8" BorderBrush="{DynamicResource BorderBrushColor}" 
                BorderThickness="2" CacheMode="BitmapCache" SnapsToDevicePixels="True" UseLayoutRounding="True">
                            <ScrollViewer Style="{StaticResource CustomScrollViewer}" VerticalScrollBarVisibility="Auto">
                                <StackPanel Margin="20">
                                    
                                    <!-- Browsers -->
                                    <TextBlock Text="Browsers" FontSize="16" FontWeight="Bold" 
                                               Foreground="#4F8EF7" Margin="0,0,0,12"/>
                                    <WrapPanel Margin="0,0,0,15">
                                        <Border Name="BtnBrave" Background="Transparent" CornerRadius="6" 
                                                Padding="15,10" Margin="0,0,10,10" Cursor="Hand">
                                            <TextBlock Text="Brave" FontSize="14" Foreground="{DynamicResource ForegroundBrush}"/>
                                        </Border>
                                        <Border Name="BtnChrome" Background="Transparent" CornerRadius="6" 
                                                Padding="15,10" Margin="0,0,10,10" Cursor="Hand">
                                            <TextBlock Text="Chrome" FontSize="14" Foreground="{DynamicResource ForegroundBrush}"/>
                                        </Border>
                                        <Border Name="BtnChromium" Background="Transparent" CornerRadius="6" 
                                                Padding="15,10" Margin="0,0,10,10" Cursor="Hand">
                                            <TextBlock Text="Chromium" FontSize="14" Foreground="{DynamicResource ForegroundBrush}"/>
                                        </Border>
                                        <Border Name="BtnEdge" Background="Transparent" CornerRadius="6" 
                                                Padding="15,10" Margin="0,0,10,10" Cursor="Hand">
                                            <TextBlock Text="Edge" FontSize="14" Foreground="{DynamicResource ForegroundBrush}"/>
                                        </Border>
                                        <Border Name="BtnFalkon" Background="Transparent" CornerRadius="6" 
                                                Padding="15,10" Margin="0,0,10,10" Cursor="Hand">
                                            <TextBlock Text="Falkon" FontSize="14" Foreground="{DynamicResource ForegroundBrush}"/>
                                        </Border>
                                        <Border Name="BtnFirefox" Background="Transparent" CornerRadius="6" 
                                                Padding="15,10" Margin="0,0,10,10" Cursor="Hand">
                                            <TextBlock Text="Firefox" FontSize="14" Foreground="{DynamicResource ForegroundBrush}"/>
                                        </Border>
                                        <Border Name="BtnFirefoxESR" Background="Transparent" CornerRadius="6" 
                                                Padding="15,10" Margin="0,0,10,10" Cursor="Hand">
                                            <TextBlock Text="Firefox ESR" FontSize="14" Foreground="{DynamicResource ForegroundBrush}"/>
                                        </Border>
                                        <Border Name="BtnFloorp" Background="Transparent" CornerRadius="6" 
                                                Padding="15,10" Margin="0,0,10,10" Cursor="Hand">
                                            <TextBlock Text="Floorp" FontSize="14" Foreground="{DynamicResource ForegroundBrush}"/>
                                        </Border>
                                        <Border Name="BtnLibreWolf" Background="Transparent" CornerRadius="6" 
                                                Padding="15,10" Margin="0,0,10,10" Cursor="Hand">
                                            <TextBlock Text="LibreWolf" FontSize="14" Foreground="{DynamicResource ForegroundBrush}"/>
                                        </Border>
                                        <Border Name="BtnMullvadBrowser" Background="Transparent" CornerRadius="6" 
                                                Padding="15,10" Margin="0,0,10,10" Cursor="Hand">
                                            <TextBlock Text="Mullvad Browser" FontSize="14" Foreground="{DynamicResource ForegroundBrush}"/>
                                        </Border>
                                        <Border Name="BtnPaleMoon" Background="Transparent" CornerRadius="6" 
                                                Padding="15,10" Margin="0,0,10,10" Cursor="Hand">
                                            <TextBlock Text="PaleMoon" FontSize="14" Foreground="{DynamicResource ForegroundBrush}"/>
                                        </Border>
                                        <Border Name="BtnThorium" Background="Transparent" CornerRadius="6" 
                                                Padding="15,10" Margin="0,0,10,10" Cursor="Hand">
                                            <TextBlock Text="Thorium Browser" FontSize="14" Foreground="{DynamicResource ForegroundBrush}"/>
                                        </Border>
                                        <Border Name="BtnTorBrowser" Background="Transparent" CornerRadius="6" 
                                                Padding="15,10" Margin="0,0,10,10" Cursor="Hand">
                                            <TextBlock Text="Tor Browser" FontSize="14" Foreground="{DynamicResource ForegroundBrush}"/>
                                        </Border>
                                        <Border Name="BtnUngoogled" Background="Transparent" CornerRadius="6" 
                                                Padding="15,10" Margin="0,0,10,10" Cursor="Hand">
                                            <TextBlock Text="Ungoogled Chromium" FontSize="14" Foreground="{DynamicResource ForegroundBrush}"/>
                                        </Border>
                                        <Border Name="BtnVivaldi" Background="Transparent" CornerRadius="6" 
                                                Padding="15,10" Margin="0,0,10,10" Cursor="Hand">
                                            <TextBlock Text="Vivaldi" FontSize="14" Foreground="{DynamicResource ForegroundBrush}"/>
                                        </Border>
                                        <Border Name="BtnWaterfox" Background="Transparent" CornerRadius="6" 
                                                Padding="15,10" Margin="0,0,10,10" Cursor="Hand">
                                            <TextBlock Text="Waterfox" FontSize="14" Foreground="{DynamicResource ForegroundBrush}"/>
                                        </Border>
                                        <Border Name="BtnZenBrowser" Background="Transparent" CornerRadius="6" 
                                                Padding="15,10" Margin="0,0,10,10" Cursor="Hand">
                                            <TextBlock Text="Zen Browser" FontSize="14" Foreground="{DynamicResource ForegroundBrush}"/>
                                        </Border>
                                    </WrapPanel>
                                    <Separator Background="{DynamicResource BorderBrushColor}" Height="1" Margin="0,0,0,15"/>
                                    
                                    <!-- Game Launchers -->
                                    <TextBlock Text="Game Launchers" FontSize="16" FontWeight="Bold" 
                                               Foreground="#4F8EF7" Margin="0,0,0,12"/>
                                    <WrapPanel Margin="0,0,0,15">
                                        <Border Name="BtnSteam" Background="Transparent" CornerRadius="6" 
                                                Padding="15,10" Margin="0,0,10,10" Cursor="Hand">
                                            <TextBlock Text="Steam" FontSize="14" Foreground="{DynamicResource ForegroundBrush}"/>
                                        </Border>
                                        <Border Name="BtnEpicGames" Background="Transparent" CornerRadius="6" 
                                                Padding="15,10" Margin="0,0,10,10" Cursor="Hand">
                                            <TextBlock Text="Epic Games" FontSize="14" Foreground="{DynamicResource ForegroundBrush}"/>
                                        </Border>
                                        <Border Name="BtnEAApp" Background="Transparent" CornerRadius="6" 
                                                Padding="15,10" Margin="0,0,10,10" Cursor="Hand">
                                            <TextBlock Text="EA App" FontSize="14" Foreground="{DynamicResource ForegroundBrush}"/>
                                        </Border>
                                        <Border Name="BtnUbisoft" Background="Transparent" CornerRadius="6" 
                                                Padding="15,10" Margin="0,0,10,10" Cursor="Hand">
                                            <TextBlock Text="Ubisoft Connect" FontSize="14" Foreground="{DynamicResource ForegroundBrush}"/>
                                        </Border>
                                        <Border Name="BtnGOG" Background="Transparent" CornerRadius="6" 
                                                Padding="15,10" Margin="0,0,10,10" Cursor="Hand">
                                            <TextBlock Text="GOG Galaxy" FontSize="14" Foreground="{DynamicResource ForegroundBrush}"/>
                                        </Border>
                                    </WrapPanel>
                                    <Separator Background="{DynamicResource BorderBrushColor}" Height="1" Margin="0,0,0,15"/>
                                    
                                    <!-- Proton Apps -->
                                    <TextBlock Text="Proton Apps" FontSize="16" FontWeight="Bold" 
                                               Foreground="#4F8EF7" Margin="0,0,0,12"/>
                                    <WrapPanel Margin="0,0,0,15">
                                        <Border Name="BtnProtonVPN" Background="Transparent" CornerRadius="6" 
                                                Padding="15,10" Margin="0,0,10,10" Cursor="Hand">
                                            <TextBlock Text="Proton VPN" FontSize="14" Foreground="{DynamicResource ForegroundBrush}"/>
                                        </Border>
                                        <Border Name="BtnProtonMail" Background="Transparent" CornerRadius="6" 
                                                Padding="15,10" Margin="0,0,10,10" Cursor="Hand">
                                            <TextBlock Text="Proton Mail" FontSize="14" Foreground="{DynamicResource ForegroundBrush}"/>
                                        </Border>
                                        <Border Name="BtnProtonDrive" Background="Transparent" CornerRadius="6" 
                                                Padding="15,10" Margin="0,0,10,10" Cursor="Hand">
                                            <TextBlock Text="Proton Drive" FontSize="14" Foreground="{DynamicResource ForegroundBrush}"/>
                                        </Border>
                                        <Border Name="BtnProtonPass" Background="Transparent" CornerRadius="6" 
                                                Padding="15,10" Margin="0,0,10,10" Cursor="Hand">
                                            <TextBlock Text="Proton Pass" FontSize="14" Foreground="{DynamicResource ForegroundBrush}"/>
                                        </Border>
                                    </WrapPanel>
                                    <Separator Background="{DynamicResource BorderBrushColor}" Height="1" Margin="0,0,0,15"/>
                                    
                                    <!-- Development Tools -->
                                    <TextBlock Text="Development Tools" FontSize="16" FontWeight="Bold" 
                                               Foreground="#4F8EF7" Margin="0,0,0,12"/>
                                    <WrapPanel Margin="0,0,0,15">
                                        <Border Name="BtnAegisub" Background="Transparent" CornerRadius="6" 
                                                Padding="15,10" Margin="0,0,10,10" Cursor="Hand">
                                            <TextBlock Text="Aegisub" FontSize="14" Foreground="{DynamicResource ForegroundBrush}"/>
                                        </Border>
                                        <Border Name="BtnAnaconda" Background="Transparent" CornerRadius="6" 
                                                Padding="15,10" Margin="0,0,10,10" Cursor="Hand">
                                            <TextBlock Text="Anaconda" FontSize="14" Foreground="{DynamicResource ForegroundBrush}"/>
                                        </Border>
                                        <Border Name="BtnClink" Background="Transparent" CornerRadius="6" 
                                                Padding="15,10" Margin="0,0,10,10" Cursor="Hand">
                                            <TextBlock Text="Clink" FontSize="14" Foreground="{DynamicResource ForegroundBrush}"/>
                                        </Border>
                                        <Border Name="BtnCMake" Background="Transparent" CornerRadius="6" 
                                                Padding="15,10" Margin="0,0,10,10" Cursor="Hand">
                                            <TextBlock Text="CMake" FontSize="14" Foreground="{DynamicResource ForegroundBrush}"/>
                                        </Border>
                                        <Border Name="BtnDaxStudio" Background="Transparent" CornerRadius="6" 
                                                Padding="15,10" Margin="0,0,10,10" Cursor="Hand">
                                            <TextBlock Text="DaxStudio" FontSize="14" Foreground="{DynamicResource ForegroundBrush}"/>
                                        </Border>
                                        <Border Name="BtnDocker" Background="Transparent" CornerRadius="6" 
                                                Padding="15,10" Margin="0,0,10,10" Cursor="Hand">
                                            <TextBlock Text="Docker Desktop" FontSize="14" Foreground="{DynamicResource ForegroundBrush}"/>
                                        </Border>
                                        <Border Name="BtnFNM" Background="Transparent" CornerRadius="6" 
                                                Padding="15,10" Margin="0,0,10,10" Cursor="Hand">
                                            <TextBlock Text="Fast Node Manager" FontSize="14" Foreground="{DynamicResource ForegroundBrush}"/>
                                        </Border>
                                        <Border Name="BtnFork" Background="Transparent" CornerRadius="6" 
                                                Padding="15,10" Margin="0,0,10,10" Cursor="Hand">
                                            <TextBlock Text="Fork" FontSize="14" Foreground="{DynamicResource ForegroundBrush}"/>
                                        </Border>
                                        <Border Name="BtnGit" Background="Transparent" CornerRadius="6" 
                                                Padding="15,10" Margin="0,0,10,10" Cursor="Hand">
                                            <TextBlock Text="Git" FontSize="14" Foreground="{DynamicResource ForegroundBrush}"/>
                                        </Border>
                                        <Border Name="BtnGitButler" Background="Transparent" CornerRadius="6" 
                                                Padding="15,10" Margin="0,0,10,10" Cursor="Hand">
                                            <TextBlock Text="Git Butler" FontSize="14" Foreground="{DynamicResource ForegroundBrush}"/>
                                        </Border>
                                        <Border Name="BtnGitExtensions" Background="Transparent" CornerRadius="6" 
                                                Padding="15,10" Margin="0,0,10,10" Cursor="Hand">
                                            <TextBlock Text="Git Extensions" FontSize="14" Foreground="{DynamicResource ForegroundBrush}"/>
                                        </Border>
                                        <Border Name="BtnGitHubCLI" Background="Transparent" CornerRadius="6" 
                                                Padding="15,10" Margin="0,0,10,10" Cursor="Hand">
                                            <TextBlock Text="GitHub CLI" FontSize="14" Foreground="{DynamicResource ForegroundBrush}"/>
                                        </Border>
                                        <Border Name="BtnGitHubDesktop" Background="Transparent" CornerRadius="6" 
                                                Padding="15,10" Margin="0,0,10,10" Cursor="Hand">
                                            <TextBlock Text="GitHub Desktop" FontSize="14" Foreground="{DynamicResource ForegroundBrush}"/>
                                        </Border>
                                        <Border Name="BtnGitify" Background="Transparent" CornerRadius="6" 
                                                Padding="15,10" Margin="0,0,10,10" Cursor="Hand">
                                            <TextBlock Text="Gitify" FontSize="14" Foreground="{DynamicResource ForegroundBrush}"/>
                                        </Border>
                                        <Border Name="BtnGitKraken" Background="Transparent" CornerRadius="6" 
                                                Padding="15,10" Margin="0,0,10,10" Cursor="Hand">
                                            <TextBlock Text="GitKraken Client" FontSize="14" Foreground="{DynamicResource ForegroundBrush}"/>
                                        </Border>
                                        <Border Name="BtnGodot" Background="Transparent" CornerRadius="6" 
                                                Padding="15,10" Margin="0,0,10,10" Cursor="Hand">
                                            <TextBlock Text="Godot Engine" FontSize="14" Foreground="{DynamicResource ForegroundBrush}"/>
                                        </Border>
                                        <Border Name="BtnGo" Background="Transparent" CornerRadius="6" 
                                                Padding="15,10" Margin="0,0,10,10" Cursor="Hand">
                                            <TextBlock Text="Go" FontSize="14" Foreground="{DynamicResource ForegroundBrush}"/>
                                        </Border>
                                        <Border Name="BtnHelix" Background="Transparent" CornerRadius="6" 
                                                Padding="15,10" Margin="0,0,10,10" Cursor="Hand">
                                            <TextBlock Text="Helix" FontSize="14" Foreground="{DynamicResource ForegroundBrush}"/>
                                        </Border>
                                        <Border Name="BtnCorretto11" Background="Transparent" CornerRadius="6" 
                                                Padding="15,10" Margin="0,0,10,10" Cursor="Hand">
                                            <TextBlock Text="Corretto 11 (LTS)" FontSize="14" Foreground="{DynamicResource ForegroundBrush}"/>
                                        </Border>
                                        <Border Name="BtnCorretto17" Background="Transparent" CornerRadius="6" 
                                                Padding="15,10" Margin="0,0,10,10" Cursor="Hand">
                                            <TextBlock Text="Corretto 17 (LTS)" FontSize="14" Foreground="{DynamicResource ForegroundBrush}"/>
                                        </Border>
                                        <Border Name="BtnCorretto21" Background="Transparent" CornerRadius="6" 
                                                Padding="15,10" Margin="0,0,10,10" Cursor="Hand">
                                            <TextBlock Text="Corretto 21 (LTS)" FontSize="14" Foreground="{DynamicResource ForegroundBrush}"/>
                                        </Border>
                                        <Border Name="BtnCorretto8" Background="Transparent" CornerRadius="6" 
                                                Padding="15,10" Margin="0,0,10,10" Cursor="Hand">
                                            <TextBlock Text="Corretto 8 (LTS)" FontSize="14" Foreground="{DynamicResource ForegroundBrush}"/>
                                        </Border>
                                        <Border Name="BtnJetbrainsToolbox" Background="Transparent" CornerRadius="6" 
                                                Padding="15,10" Margin="0,0,10,10" Cursor="Hand">
                                            <TextBlock Text="Jetbrains Toolbox" FontSize="14" Foreground="{DynamicResource ForegroundBrush}"/>
                                        </Border>
                                        <Border Name="BtnLazygit" Background="Transparent" CornerRadius="6" 
                                                Padding="15,10" Margin="0,0,10,10" Cursor="Hand">
                                            <TextBlock Text="Lazygit" FontSize="14" Foreground="{DynamicResource ForegroundBrush}"/>
                                        </Border>
                                        <Border Name="BtnMiniconda" Background="Transparent" CornerRadius="6" 
                                                Padding="15,10" Margin="0,0,10,10" Cursor="Hand">
                                            <TextBlock Text="Miniconda" FontSize="14" Foreground="{DynamicResource ForegroundBrush}"/>
                                        </Border>
                                        <Border Name="BtnMu" Background="Transparent" CornerRadius="6" 
                                                Padding="15,10" Margin="0,0,10,10" Cursor="Hand">
                                            <TextBlock Text="Mu Editor" FontSize="14" Foreground="{DynamicResource ForegroundBrush}"/>
                                        </Border>
                                        <Border Name="BtnNeovim" Background="Transparent" CornerRadius="6" 
                                                Padding="15,10" Margin="0,0,10,10" Cursor="Hand">
                                            <TextBlock Text="Neovim" FontSize="14" Foreground="{DynamicResource ForegroundBrush}"/>
                                        </Border>
                                        <Border Name="BtnNodeJS" Background="Transparent" CornerRadius="6" 
                                                Padding="15,10" Margin="0,0,10,10" Cursor="Hand">
                                            <TextBlock Text="NodeJS" FontSize="14" Foreground="{DynamicResource ForegroundBrush}"/>
                                        </Border>
                                        <Border Name="BtnNodeJSLTS" Background="Transparent" CornerRadius="6" 
                                                Padding="15,10" Margin="0,0,10,10" Cursor="Hand">
                                            <TextBlock Text="NodeJS LTS" FontSize="14" Foreground="{DynamicResource ForegroundBrush}"/>
                                        </Border>
                                        <Border Name="BtnNVM" Background="Transparent" CornerRadius="6" 
                                                Padding="15,10" Margin="0,0,10,10" Cursor="Hand">
                                            <TextBlock Text="Node Version Manager" FontSize="14" Foreground="{DynamicResource ForegroundBrush}"/>
                                        </Border>
                                        <Border Name="BtnPixi" Background="Transparent" CornerRadius="6" 
                                                Padding="15,10" Margin="0,0,10,10" Cursor="Hand">
                                            <TextBlock Text="Pixi" FontSize="14" Foreground="{DynamicResource ForegroundBrush}"/>
                                        </Border>
                                        <Border Name="BtnOhMyPosh" Background="Transparent" CornerRadius="6" 
                                                Padding="15,10" Margin="0,0,10,10" Cursor="Hand">
                                            <TextBlock Text="Oh My Posh" FontSize="14" Foreground="{DynamicResource ForegroundBrush}"/>
                                        </Border>
                                        <Border Name="BtnPostman" Background="Transparent" CornerRadius="6" 
                                                Padding="15,10" Margin="0,0,10,10" Cursor="Hand">
                                            <TextBlock Text="Postman" FontSize="14" Foreground="{DynamicResource ForegroundBrush}"/>
                                        </Border>
                                        <Border Name="BtnPulsar" Background="Transparent" CornerRadius="6" 
                                                Padding="15,10" Margin="0,0,10,10" Cursor="Hand">
                                            <TextBlock Text="Pulsar" FontSize="14" Foreground="{DynamicResource ForegroundBrush}"/>
                                        </Border>
                                        <Border Name="BtnPyenv" Background="Transparent" CornerRadius="6" 
                                                Padding="15,10" Margin="0,0,10,10" Cursor="Hand">
                                            <TextBlock Text="Python Version Manager" FontSize="14" Foreground="{DynamicResource ForegroundBrush}"/>
                                        </Border>
                                        <Border Name="BtnPython" Background="Transparent" CornerRadius="6" 
                                                Padding="15,10" Margin="0,0,10,10" Cursor="Hand">
                                            <TextBlock Text="Python 3" FontSize="14" Foreground="{DynamicResource ForegroundBrush}"/>
                                        </Border>
                                        <Border Name="BtnRust" Background="Transparent" CornerRadius="6" 
                                                Padding="15,10" Margin="0,0,10,10" Cursor="Hand">
                                            <TextBlock Text="Rust" FontSize="14" Foreground="{DynamicResource ForegroundBrush}"/>
                                        </Border>
                                        <Border Name="BtnStarship" Background="Transparent" CornerRadius="6" 
                                                Padding="15,10" Margin="0,0,10,10" Cursor="Hand">
                                            <TextBlock Text="Starship" FontSize="14" Foreground="{DynamicResource ForegroundBrush}"/>
                                        </Border>
                                        <Border Name="BtnSublimeMerge" Background="Transparent" CornerRadius="6" 
                                                Padding="15,10" Margin="0,0,10,10" Cursor="Hand">
                                            <TextBlock Text="Sublime Merge" FontSize="14" Foreground="{DynamicResource ForegroundBrush}"/>
                                        </Border>
                                        <Border Name="BtnSublimeText" Background="Transparent" CornerRadius="6" 
                                                Padding="15,10" Margin="0,0,10,10" Cursor="Hand">
                                            <TextBlock Text="Sublime Text" FontSize="14" Foreground="{DynamicResource ForegroundBrush}"/>
                                        </Border>
                                        <Border Name="BtnSwift" Background="Transparent" CornerRadius="6" 
                                                Padding="15,10" Margin="0,0,10,10" Cursor="Hand">
                                            <TextBlock Text="Swift" FontSize="14" Foreground="{DynamicResource ForegroundBrush}"/>
                                        </Border>
                                        <Border Name="BtnTemurin" Background="Transparent" CornerRadius="6" 
                                                Padding="15,10" Margin="0,0,10,10" Cursor="Hand">
                                            <TextBlock Text="Eclipse Temurin" FontSize="14" Foreground="{DynamicResource ForegroundBrush}"/>
                                        </Border>
                                        <Border Name="BtnThonny" Background="Transparent" CornerRadius="6" 
                                                Padding="15,10" Margin="0,0,10,10" Cursor="Hand">
                                            <TextBlock Text="Thonny" FontSize="14" Foreground="{DynamicResource ForegroundBrush}"/>
                                        </Border>
                                        <Border Name="BtnUnity" Background="Transparent" CornerRadius="6" 
                                                Padding="15,10" Margin="0,0,10,10" Cursor="Hand">
                                            <TextBlock Text="Unity Hub" FontSize="14" Foreground="{DynamicResource ForegroundBrush}"/>
                                        </Border>
                                        <Border Name="BtnVagrant" Background="Transparent" CornerRadius="6" 
                                                Padding="15,10" Margin="0,0,10,10" Cursor="Hand">
                                            <TextBlock Text="Vagrant" FontSize="14" Foreground="{DynamicResource ForegroundBrush}"/>
                                        </Border>
                                        <Border Name="BtnVisualStudio2022" Background="Transparent" CornerRadius="6" 
                                                Padding="15,10" Margin="0,0,10,10" Cursor="Hand">
                                            <TextBlock Text="Visual Studio 2022" FontSize="14" Foreground="{DynamicResource ForegroundBrush}"/>
                                        </Border>
                                        <Border Name="BtnVSCode" Background="Transparent" CornerRadius="6" 
                                                Padding="15,10" Margin="0,0,10,10" Cursor="Hand">
                                            <TextBlock Text="VS Code" FontSize="14" Foreground="{DynamicResource ForegroundBrush}"/>
                                        </Border>
                                        <Border Name="BtnVSCodium" Background="Transparent" CornerRadius="6" 
                                                Padding="15,10" Margin="0,0,10,10" Cursor="Hand">
                                            <TextBlock Text="VS Codium" FontSize="14" Foreground="{DynamicResource ForegroundBrush}"/>
                                        </Border>
                                        <Border Name="BtnWezterm" Background="Transparent" CornerRadius="6" 
                                                Padding="15,10" Margin="0,0,10,10" Cursor="Hand">
                                            <TextBlock Text="Wezterm" FontSize="14" Foreground="{DynamicResource ForegroundBrush}"/>
                                        </Border>
                                        <Border Name="BtnYarn" Background="Transparent" CornerRadius="6" 
                                                Padding="15,10" Margin="0,0,10,10" Cursor="Hand">
                                            <TextBlock Text="Yarn" FontSize="14" Foreground="{DynamicResource ForegroundBrush}"/>
                                        </Border>
                                    </WrapPanel>
                                    <Separator Background="{DynamicResource BorderBrushColor}" Height="1" Margin="0,0,0,15"/>
                                    
                                    <!-- Media & Communication -->
                                    <TextBlock Text="Media &amp; Communication" FontSize="16" FontWeight="Bold" 
                                               Foreground="#4F8EF7" Margin="0,0,0,12"/>
                                    <WrapPanel Margin="0,0,0,15">
                                        <Border Name="BtnDiscord" Background="Transparent" CornerRadius="6" 
                                                Padding="15,10" Margin="0,0,10,10" Cursor="Hand">
                                            <TextBlock Text="Discord" FontSize="14" Foreground="{DynamicResource ForegroundBrush}"/>
                                        </Border>
                                        <Border Name="BtnSpotify" Background="Transparent" CornerRadius="6" 
                                                Padding="15,10" Margin="0,0,10,10" Cursor="Hand">
                                            <TextBlock Text="Spotify" FontSize="14" Foreground="{DynamicResource ForegroundBrush}"/>
                                        </Border>
                                        <Border Name="BtnVLC" Background="Transparent" CornerRadius="6" 
                                                Padding="15,10" Margin="0,0,10,10" Cursor="Hand">
                                            <TextBlock Text="VLC" FontSize="14" Foreground="{DynamicResource ForegroundBrush}"/>
                                        </Border>
                                    </WrapPanel>
                                    <Separator Background="{DynamicResource BorderBrushColor}" Height="1" Margin="0,0,0,15"/>
                                    
                                    <!-- Utilities -->
                                    <TextBlock Text="Utilities" FontSize="16" FontWeight="Bold" 
                                               Foreground="#4F8EF7" Margin="0,0,0,12"/>
                                    <WrapPanel Margin="0,0,0,15">
                                        <Border Name="Btn7Zip" Background="Transparent" CornerRadius="6" 
                                                Padding="15,10" Margin="0,0,10,10" Cursor="Hand">
                                            <TextBlock Text="7-Zip" FontSize="14" Foreground="{DynamicResource ForegroundBrush}"/>
                                        </Border>
                                        <Border Name="BtnNotepadPlusPlus" Background="Transparent" CornerRadius="6" 
                                                Padding="15,10" Margin="0,0,10,10" Cursor="Hand">
                                            <TextBlock Text="Notepad++" FontSize="14" Foreground="{DynamicResource ForegroundBrush}"/>
                                        </Border>
                                        <Border Name="BtnOBS" Background="Transparent" CornerRadius="6" 
                                                Padding="15,10" Margin="0,0,10,10" Cursor="Hand">
                                            <TextBlock Text="OBS Studio" FontSize="14" Foreground="{DynamicResource ForegroundBrush}"/>
                                        </Border>
                                    </WrapPanel>
                                    
                                </StackPanel>
                            </ScrollViewer>
                        </Border>
                    </Grid>

                    <!-- Tweaks -->
                    <Grid Name="PageTweaks" Visibility="Collapsed">
                        <Grid.RowDefinitions>
                            <RowDefinition Height="Auto"/>
                            <RowDefinition Height="*"/>
                        </Grid.RowDefinitions>

                        <!-- Removed top toolbar; buttons will appear fixed at bottom of the left card -->
                        <Border Grid.Row="0" Visibility="Collapsed"/>

                        <!-- Content area with two columns -->
                        <Grid Grid.Row="1">
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="*"/>
                            </Grid.ColumnDefinitions>

                            <!-- Left: Advanced Tweaks -->
                            <Border Grid.Column="0" Margin="12,8,12,8" Background="{DynamicResource CardBrush}"
                                    CornerRadius="12" BorderThickness="2" BorderBrush="{DynamicResource BorderBrushColor}">
                                <Grid>
                                    <Grid.RowDefinitions>
                                        <RowDefinition Height="*"/>
                                        <RowDefinition Height="Auto"/>
                                    </Grid.RowDefinitions>

                                    <ScrollViewer Grid.Row="0" Style="{StaticResource CustomScrollViewer}" VerticalScrollBarVisibility="Auto">
                                        <StackPanel Margin="24">
                                        <!-- Normal Tweaks Section -->
                                        <TextBlock Text="Basic Tweaks" FontSize="18" FontWeight="Bold"
                                                   Foreground="#4CAF50" Margin="0,0,0,12"/>
                                        <CheckBox Name="ChkPreferIPv4" Content="Prefer IPv4 over IPv6" Style="{StaticResource ToggleSwitchStyle}" Margin="0,0,0,8" FontSize="14"/>
                                        <CheckBox Name="ChkDisableBackgroundApps" Content="Disable Background Apps" Style="{StaticResource ToggleSwitchStyle}" Margin="0,0,0,8" FontSize="14"/>
                                        <CheckBox Name="ChkDisableFullscreenOptimizations" Content="Disable Fullscreen Optimizations" Style="{StaticResource ToggleSwitchStyle}" Margin="0,0,0,8" FontSize="14"/>
                                        <CheckBox Name="ChkDisableNotificationTray" Content="Disable Notification Tray/Calendar" Style="{StaticResource ToggleSwitchStyle}" Margin="0,0,0,8" FontSize="14"/>
                                        <CheckBox Name="ChkSetClassicRightClick" Content="Set Classic Right-Click Menu" Style="{StaticResource ToggleSwitchStyle}" Margin="0,0,0,8" FontSize="14"/>
                                        <CheckBox Name="ChkSetDisplayPerformance" Content="Set Display for Performance" Style="{StaticResource ToggleSwitchStyle}" Margin="0,0,0,8" FontSize="14"/>
                                        <CheckBox Name="ChkSetTimeUTC" Content="Set Time to UTC (Dual Boot)" Style="{StaticResource ToggleSwitchStyle}" Margin="0,0,0,8" FontSize="14"/>
                                        <CheckBox Name="ChkDeleteTempFiles" Content="Delete Temporary Files" Style="{StaticResource ToggleSwitchStyle}" Margin="0,0,0,8" FontSize="14"/>
                                        <CheckBox Name="ChkDisableConsumerFeatures" Content="Disable ConsumerFeatures" Style="{StaticResource ToggleSwitchStyle}" Margin="0,0,0,8" FontSize="14"/>
                                        <CheckBox Name="ChkDisableTelemetry" Content="Disable Telemetry" Style="{StaticResource ToggleSwitchStyle}" Margin="0,0,0,8" FontSize="14"/>
                                        <CheckBox Name="ChkDisableActivityHistory" Content="Disable Activity History" Style="{StaticResource ToggleSwitchStyle}" Margin="0,0,0,8" FontSize="14"/>
                                        <CheckBox Name="ChkDisableExplorerFolderDiscovery" Content="Disable Explorer Automatic Folder Discovery" Style="{StaticResource ToggleSwitchStyle}" Margin="0,0,0,8" FontSize="14"/>
                                        <CheckBox Name="ChkDisableGameDVR" Content="Disable GameDVR" Style="{StaticResource ToggleSwitchStyle}" Margin="0,0,0,8" FontSize="14"/>
                                        <CheckBox Name="ChkDisableHomegroup" Content="Disable Homegroup" Style="{StaticResource ToggleSwitchStyle}" Margin="0,0,0,8" FontSize="14"/>
                                        <CheckBox Name="ChkDisableLocationTracking" Content="Disable Location Tracking" Style="{StaticResource ToggleSwitchStyle}" Margin="0,0,0,8" FontSize="14"/>
                                        <CheckBox Name="ChkDisableStorageSense" Content="Disable Storage Sense" Style="{StaticResource ToggleSwitchStyle}" Margin="0,0,0,8" FontSize="14"/>
                                        <CheckBox Name="ChkDisableWifiSense" Content="Disable Wifi-Sense" Style="{StaticResource ToggleSwitchStyle}" Margin="0,0,0,8" FontSize="14"/>
                                        <CheckBox Name="ChkEnableEndTaskRightClick" Content="Enable End Task With Right Click" Style="{StaticResource ToggleSwitchStyle}" Margin="0,0,0,8" FontSize="14"/>
                                        <CheckBox Name="ChkSetTerminalDefault" Content="Change Windows Terminal Default" Style="{StaticResource ToggleSwitchStyle}" Margin="0,0,0,8" FontSize="14"/>
                                        <CheckBox Name="ChkDisablePS7Telemetry" Content="Disable PowerShell 7 Telemetry" Style="{StaticResource ToggleSwitchStyle}" Margin="0,0,0,8" FontSize="14"/>
                                        <CheckBox Name="ChkDisableRecall" Content="Disable Recall" Style="{StaticResource ToggleSwitchStyle}" Margin="0,0,0,8" FontSize="14"/>
                                        <CheckBox Name="ChkSetHibernationDefault" Content="Set Hibernation as Default (Undo)" Style="{StaticResource ToggleSwitchStyle}" Margin="0,0,0,8" FontSize="14"/>
                                        <CheckBox Name="ChkDebloatBrave" Content="Debloat Brave" Style="{StaticResource ToggleSwitchStyle}" Margin="0,0,0,8" FontSize="14"/>
                                        <CheckBox Name="ChkDebloatEdge" Content="Debloat Edge" Style="{StaticResource ToggleSwitchStyle}" Margin="0,0,0,8" FontSize="14"/>

                                        <Separator Margin="0,12,0,12"/>
                                        <!-- Advanced Tweaks Section -->
                                        <TextBlock Text="Advanced Tweaks - CAUTION" FontSize="18" FontWeight="Bold"
                                                   Foreground="#FF5555" Margin="0,0,0,12"/>
                                        <CheckBox Name="ChkDisableIPv6" Content="Disable IPv6" Style="{StaticResource ToggleSwitchStyle}" Margin="0,0,0,8" FontSize="14"/>
                                        <CheckBox Name="ChkBlockAdobeNetwork" Content="Block Adobe Network" Style="{StaticResource ToggleSwitchStyle}" Margin="0,0,0,8" FontSize="14"/>
                                        <CheckBox Name="ChkDebloatAdobe" Content="Debloat Adobe" Style="{StaticResource ToggleSwitchStyle}" Margin="0,0,0,8" FontSize="14"/>
                                        <CheckBox Name="ChkDisableTeredo" Content="Disable Teredo" Style="{StaticResource ToggleSwitchStyle}" Margin="0,0,0,8" FontSize="14"/>
                                        <CheckBox Name="ChkDisableCopilot" Content="Disable Microsoft Copilot" Style="{StaticResource ToggleSwitchStyle}" Margin="0,0,0,8" FontSize="14"/>
                                        <CheckBox Name="ChkDisableIntelMM" Content="Disable Intel MM (vPro LMS)" Style="{StaticResource ToggleSwitchStyle}" Margin="0,0,0,8" FontSize="14"/>
                                        <CheckBox Name="ChkDisableWPBT" Content="Disable WPBT" Style="{StaticResource ToggleSwitchStyle}" Margin="0,0,0,8" FontSize="14"/>
                                        <CheckBox Name="ChkRemoveMSStoreApps" Content="Remove ALL MS Store Apps" Style="{StaticResource ToggleSwitchStyle}" Margin="0,0,0,8" FontSize="14"/>
                                        <CheckBox Name="ChkRemoveHomeFromExplorer" Content="Remove Home from Explorer" Style="{StaticResource ToggleSwitchStyle}" Margin="0,0,0,8" FontSize="14"/>
                                        <CheckBox Name="ChkRemoveGalleryFromExplorer" Content="Remove Gallery from Explorer" Style="{StaticResource ToggleSwitchStyle}" Margin="0,0,0,8" FontSize="14"/>
                                        <CheckBox Name="ChkRemoveOneDrive" Content="Remove OneDrive" Style="{StaticResource ToggleSwitchStyle}" Margin="0,0,0,8" FontSize="14"/>
                                        <CheckBox Name="ChkBlockRazerSoftware" Content="Block Razer Software" Style="{StaticResource ToggleSwitchStyle}" Margin="0,0,0,8" FontSize="14"/>
                                        <CheckBox Name="ChkDisableHibernation" Content="Disable Hibernation" Style="{StaticResource ToggleSwitchStyle}" Margin="0,0,0,8" FontSize="14"/>
                                        </StackPanel>
                                    </ScrollViewer>

                                    <!-- Fixed bottom actions with separator -->
                                        <StackPanel Grid.Row="1" Margin="24,0,24,16">
                                        <StackPanel.Resources>
                                            <Style TargetType="Button" BasedOn="{StaticResource RoundedButton}">
                                                <Setter Property="Background" Value="Transparent"/>
                                                <Setter Property="BorderBrush" Value="{DynamicResource BorderBrushColor}"/>
                                                <Setter Property="BorderThickness" Value="1"/>
                                                    <Setter Property="FontSize" Value="14"/>
                                                    <Setter Property="Padding" Value="12,6"/>
                                                <Setter Property="Margin" Value="8,0,8,0"/>
                                                <Setter Property="HorizontalAlignment" Value="Left"/>
                                                <Setter Property="VerticalAlignment" Value="Center"/>
                                            </Style>
                                        </StackPanel.Resources>
                                        <Separator Background="{DynamicResource BorderBrushColor}" Height="1" Margin="0,8,0,10"/>
                                        <StackPanel Orientation="Horizontal">
                                            <Button Name="BtnSelectRecommendedBasic" Content="Select Recommended (Basic)"/>
                                            <Button Name="BtnSelectRecommendedAdvanced" Content="Select Recommended (Advanced)"/>
                                            <Button Name="BtnRunSelectedTweaks" Content="Run Selected Tweaks"/>
                                            <Button Name="BtnSelectAllTweaks" Content="Select All"/>
                                        </StackPanel>
                                    </StackPanel>
                                </Grid>
                            </Border>

                            <!-- Right: Preferences -->
                            <Border Grid.Column="1" Margin="12,8,12,8" Background="{DynamicResource CardBrush}"
                                CornerRadius="12" BorderThickness="2" BorderBrush="{DynamicResource BorderBrushColor}">
                            <Grid>
                                <Grid.RowDefinitions>
                                    <RowDefinition Height="*"/>
                                    <RowDefinition Height="Auto"/>
                                </Grid.RowDefinitions>

                                <ScrollViewer Grid.Row="0" VerticalScrollBarVisibility="Auto">
                                    <StackPanel Margin="24">
                                        <TextBlock Text="Customize Preferences" FontSize="18" FontWeight="Bold"
                                                   Foreground="{DynamicResource ForegroundBrush}" Margin="0,0,0,15"/>
                                        <TextBlock Text="These preferences toggle instantly and show current state."
                                                   FontSize="12" Foreground="#999999" TextWrapping="Wrap" Margin="0,0,0,20"/>
                                        
                                        <!-- Dark Theme -->
                                        <Grid Margin="0,0,0,12">
                                            <Grid.ColumnDefinitions>
                                                <ColumnDefinition Width="*"/>
                                                <ColumnDefinition Width="Auto"/>
                                            </Grid.ColumnDefinitions>
                                            <TextBlock Grid.Column="0" Text="Dark Theme for Windows" FontSize="14" 
                                                       Foreground="{DynamicResource ForegroundBrush}" VerticalAlignment="Center"/>
                                            <CheckBox Grid.Column="1" Name="ChkPrefDarkTheme" 
                                                      Style="{StaticResource ToggleSwitchStyle}"/>
                                        </Grid>

                                        <!-- Bing Search -->
                                        <Grid Margin="0,0,0,12">
                                            <Grid.ColumnDefinitions>
                                                <ColumnDefinition Width="*"/>
                                                <ColumnDefinition Width="Auto"/>
                                            </Grid.ColumnDefinitions>
                                            <TextBlock Grid.Column="0" Text="Bing Search in Start Menu" FontSize="14" 
                                                       Foreground="{DynamicResource ForegroundBrush}" VerticalAlignment="Center"/>
                                            <CheckBox Grid.Column="1" Name="ChkPrefBingSearch" 
                                                      Style="{StaticResource ToggleSwitchStyle}"/>
                                        </Grid>

                                        <!-- NumLock -->
                                        <Grid Margin="0,0,0,12">
                                            <Grid.ColumnDefinitions>
                                                <ColumnDefinition Width="*"/>
                                                <ColumnDefinition Width="Auto"/>
                                            </Grid.ColumnDefinitions>
                                            <TextBlock Grid.Column="0" Text="NumLock on Startup" FontSize="14" 
                                                       Foreground="{DynamicResource ForegroundBrush}" VerticalAlignment="Center"/>
                                            <CheckBox Grid.Column="1" Name="ChkPrefNumLock" 
                                                      Style="{StaticResource ToggleSwitchStyle}"/>
                                        </Grid>

                                        <!-- Verbose Logon -->
                                        <Grid Margin="0,0,0,12">
                                            <Grid.ColumnDefinitions>
                                                <ColumnDefinition Width="*"/>
                                                <ColumnDefinition Width="Auto"/>
                                            </Grid.ColumnDefinitions>
                                            <TextBlock Grid.Column="0" Text="Verbose Messages During Logon" FontSize="14" 
                                                       Foreground="{DynamicResource ForegroundBrush}" VerticalAlignment="Center"/>
                                            <CheckBox Grid.Column="1" Name="ChkPrefVerboseLogon" 
                                                      Style="{StaticResource ToggleSwitchStyle}"/>
                                        </Grid>

                                        <!-- Start Recommendations -->
                                        <Grid Margin="0,0,0,12">
                                            <Grid.ColumnDefinitions>
                                                <ColumnDefinition Width="*"/>
                                                <ColumnDefinition Width="Auto"/>
                                            </Grid.ColumnDefinitions>
                                            <TextBlock Grid.Column="0" Text="Recommendations in Start Menu" FontSize="14" 
                                                       Foreground="{DynamicResource ForegroundBrush}" VerticalAlignment="Center"/>
                                            <CheckBox Grid.Column="1" Name="ChkPrefStartRecommendations" 
                                                      Style="{StaticResource ToggleSwitchStyle}"/>
                                        </Grid>

                                        <!-- Settings Home Page -->
                                        <Grid Margin="0,0,0,12">
                                            <Grid.ColumnDefinitions>
                                                <ColumnDefinition Width="*"/>
                                                <ColumnDefinition Width="Auto"/>
                                            </Grid.ColumnDefinitions>
                                            <TextBlock Grid.Column="0" Text="Settings Home Page" FontSize="14" 
                                                       Foreground="{DynamicResource ForegroundBrush}" VerticalAlignment="Center"/>
                                            <CheckBox Grid.Column="1" Name="ChkPrefSettingsHomePage" 
                                                      Style="{StaticResource ToggleSwitchStyle}"/>
                                        </Grid>

                                        <!-- Snap Window -->
                                        <Grid Margin="0,0,0,12">
                                            <Grid.ColumnDefinitions>
                                                <ColumnDefinition Width="*"/>
                                                <ColumnDefinition Width="Auto"/>
                                            </Grid.ColumnDefinitions>
                                            <TextBlock Grid.Column="0" Text="Snap Window" FontSize="14" 
                                                       Foreground="{DynamicResource ForegroundBrush}" VerticalAlignment="Center"/>
                                            <CheckBox Grid.Column="1" Name="ChkPrefSnapWindow" 
                                                      Style="{StaticResource ToggleSwitchStyle}"/>
                                        </Grid>

                                        <!-- Snap Assist Flyout -->
                                        <Grid Margin="0,0,0,12">
                                            <Grid.ColumnDefinitions>
                                                <ColumnDefinition Width="*"/>
                                                <ColumnDefinition Width="Auto"/>
                                            </Grid.ColumnDefinitions>
                                            <TextBlock Grid.Column="0" Text="Snap Assist Flyout" FontSize="14" 
                                                       Foreground="{DynamicResource ForegroundBrush}" VerticalAlignment="Center"/>
                                            <CheckBox Grid.Column="1" Name="ChkPrefSnapAssistFlyout" 
                                                      Style="{StaticResource ToggleSwitchStyle}"/>
                                        </Grid>

                                        <!-- Snap Assist Suggestion -->
                                        <Grid Margin="0,0,0,12">
                                            <Grid.ColumnDefinitions>
                                                <ColumnDefinition Width="*"/>
                                                <ColumnDefinition Width="Auto"/>
                                            </Grid.ColumnDefinitions>
                                            <TextBlock Grid.Column="0" Text="Snap Assist Suggestion" FontSize="14" 
                                                       Foreground="{DynamicResource ForegroundBrush}" VerticalAlignment="Center"/>
                                            <CheckBox Grid.Column="1" Name="ChkPrefSnapAssistSuggestion" 
                                                      Style="{StaticResource ToggleSwitchStyle}"/>
                                        </Grid>

                                        <!-- Mouse Acceleration -->
                                        <Grid Margin="0,0,0,12">
                                            <Grid.ColumnDefinitions>
                                                <ColumnDefinition Width="*"/>
                                                <ColumnDefinition Width="Auto"/>
                                            </Grid.ColumnDefinitions>
                                            <TextBlock Grid.Column="0" Text="Mouse Acceleration" FontSize="14" 
                                                       Foreground="{DynamicResource ForegroundBrush}" VerticalAlignment="Center"/>
                                            <CheckBox Grid.Column="1" Name="ChkPrefMouseAcceleration" 
                                                      Style="{StaticResource ToggleSwitchStyle}"/>
                                        </Grid>

                                        <!-- Sticky Keys -->
                                        <Grid Margin="0,0,0,12">
                                            <Grid.ColumnDefinitions>
                                                <ColumnDefinition Width="*"/>
                                                <ColumnDefinition Width="Auto"/>
                                            </Grid.ColumnDefinitions>
                                            <TextBlock Grid.Column="0" Text="Sticky Keys" FontSize="14" 
                                                       Foreground="{DynamicResource ForegroundBrush}" VerticalAlignment="Center"/>
                                            <CheckBox Grid.Column="1" Name="ChkPrefStickyKeys" 
                                                      Style="{StaticResource ToggleSwitchStyle}"/>
                                        </Grid>

                                        <!-- Show Hidden Files -->
                                        <Grid Margin="0,0,0,12">
                                            <Grid.ColumnDefinitions>
                                                <ColumnDefinition Width="*"/>
                                                <ColumnDefinition Width="Auto"/>
                                            </Grid.ColumnDefinitions>
                                            <TextBlock Grid.Column="0" Text="Show Hidden Files" FontSize="14" 
                                                       Foreground="{DynamicResource ForegroundBrush}" VerticalAlignment="Center"/>
                                            <CheckBox Grid.Column="1" Name="ChkPrefShowHiddenFiles" 
                                                      Style="{StaticResource ToggleSwitchStyle}"/>
                                        </Grid>

                                        <!-- Show File Extensions -->
                                        <Grid Margin="0,0,0,12">
                                            <Grid.ColumnDefinitions>
                                                <ColumnDefinition Width="*"/>
                                                <ColumnDefinition Width="Auto"/>
                                            </Grid.ColumnDefinitions>
                                            <TextBlock Grid.Column="0" Text="Show File Extensions" FontSize="14" 
                                                       Foreground="{DynamicResource ForegroundBrush}" VerticalAlignment="Center"/>
                                            <CheckBox Grid.Column="1" Name="ChkPrefShowFileExtensions" 
                                                      Style="{StaticResource ToggleSwitchStyle}"/>
                                        </Grid>

                                        <!-- Desktop Icons -->
                                        <Grid Margin="0,0,0,12">
                                            <Grid.ColumnDefinitions>
                                                <ColumnDefinition Width="*"/>
                                                <ColumnDefinition Width="Auto"/>
                                            </Grid.ColumnDefinitions>
                                            <TextBlock Grid.Column="0" Text="Show Desktop Icons" FontSize="14" 
                                                       Foreground="{DynamicResource ForegroundBrush}" VerticalAlignment="Center"/>
                                            <CheckBox Grid.Column="1" Name="ChkPrefDesktopIcons" 
                                                      Style="{StaticResource ToggleSwitchStyle}"/>
                                        </Grid>

                                        <!-- Search Button -->
                                        <Grid Margin="0,0,0,12">
                                            <Grid.ColumnDefinitions>
                                                <ColumnDefinition Width="*"/>
                                                <ColumnDefinition Width="Auto"/>
                                            </Grid.ColumnDefinitions>
                                            <TextBlock Grid.Column="0" Text="Search Button in Taskbar" FontSize="14" 
                                                       Foreground="{DynamicResource ForegroundBrush}" VerticalAlignment="Center"/>
                                            <CheckBox Grid.Column="1" Name="ChkPrefSearchButton" 
                                                      Style="{StaticResource ToggleSwitchStyle}"/>
                                        </Grid>

                                        <!-- Task View Button -->
                                        <Grid Margin="0,0,0,12">
                                            <Grid.ColumnDefinitions>
                                                <ColumnDefinition Width="*"/>
                                                <ColumnDefinition Width="Auto"/>
                                            </Grid.ColumnDefinitions>
                                            <TextBlock Grid.Column="0" Text="Task View Button in Taskbar" FontSize="14" 
                                                       Foreground="{DynamicResource ForegroundBrush}" VerticalAlignment="Center"/>
                                            <CheckBox Grid.Column="1" Name="ChkPrefTaskViewButton" 
                                                      Style="{StaticResource ToggleSwitchStyle}"/>
                                        </Grid>

                                        <!-- Center Taskbar -->
                                        <Grid Margin="0,0,0,12">
                                            <Grid.ColumnDefinitions>
                                                <ColumnDefinition Width="*"/>
                                                <ColumnDefinition Width="Auto"/>
                                            </Grid.ColumnDefinitions>
                                            <TextBlock Grid.Column="0" Text="Center Taskbar Items" FontSize="14" 
                                                       Foreground="{DynamicResource ForegroundBrush}" VerticalAlignment="Center"/>
                                            <CheckBox Grid.Column="1" Name="ChkPrefCenterTaskbar" 
                                                      Style="{StaticResource ToggleSwitchStyle}"/>
                                        </Grid>

                                        <!-- Widgets Button -->
                                        <Grid Margin="0,0,0,12">
                                            <Grid.ColumnDefinitions>
                                                <ColumnDefinition Width="*"/>
                                                <ColumnDefinition Width="Auto"/>
                                            </Grid.ColumnDefinitions>
                                            <TextBlock Grid.Column="0" Text="Widgets Button in Taskbar" FontSize="14" 
                                                       Foreground="{DynamicResource ForegroundBrush}" VerticalAlignment="Center"/>
                                            <CheckBox Grid.Column="1" Name="ChkPrefWidgetsButton" 
                                                      Style="{StaticResource ToggleSwitchStyle}"/>
                                        </Grid>

                                        <!-- Detailed BSoD -->
                                        <Grid Margin="0,0,0,12">
                                            <Grid.ColumnDefinitions>
                                                <ColumnDefinition Width="*"/>
                                                <ColumnDefinition Width="Auto"/>
                                            </Grid.ColumnDefinitions>
                                            <TextBlock Grid.Column="0" Text="Detailed BSoD" FontSize="14" 
                                                       Foreground="{DynamicResource ForegroundBrush}" VerticalAlignment="Center"/>
                                            <CheckBox Grid.Column="1" Name="ChkPrefDetailedBSoD" 
                                                      Style="{StaticResource ToggleSwitchStyle}"/>
                                        </Grid>

                                        <!-- S3 Sleep -->
                                        <Grid Margin="0,0,0,12">
                                            <Grid.ColumnDefinitions>
                                                <ColumnDefinition Width="*"/>
                                                <ColumnDefinition Width="Auto"/>
                                            </Grid.ColumnDefinitions>
                                            <TextBlock Grid.Column="0" Text="S3 Sleep" FontSize="14" 
                                                       Foreground="{DynamicResource ForegroundBrush}" VerticalAlignment="Center"/>
                                            <CheckBox Grid.Column="1" Name="ChkPrefS3Sleep" 
                                                      Style="{StaticResource ToggleSwitchStyle}"/>
                                        </Grid>
                                    </StackPanel>
                                </ScrollViewer>

                                <StackPanel Grid.Row="1" Margin="24,10,24,16">
                                    <StackPanel.Resources>
                                        <Style TargetType="Button" BasedOn="{StaticResource RoundedButton}">
                                            <Setter Property="Background" Value="Transparent"/>
                                            <Setter Property="BorderBrush" Value="{DynamicResource BorderBrushColor}"/>
                                            <Setter Property="BorderThickness" Value="1"/>
                                            <Setter Property="FontSize" Value="14"/>
                                            <Setter Property="Padding" Value="12,6"/>
                                            <Setter Property="Margin" Value="8,0,8,0"/>
                                            <Setter Property="HorizontalAlignment" Value="Stretch"/>
                                            <Setter Property="VerticalAlignment" Value="Center"/>
                                        </Style>
                                    </StackPanel.Resources>
                                    <Button Name="BtnSetRecommended" Content="Set Recommended" HorizontalAlignment="Stretch"/>
                                </StackPanel>
                            </Grid>
                        </Border>
                        </Grid>
                    </Grid>

                    <!-- Config -->
                    <Grid Name="PageConfig" Visibility="Collapsed">
                        <Grid.Resources>
                            <!-- Config-specific rounded button: inherit global, but use light gray border -->
                            <Style x:Key="ConfigRoundedButton" TargetType="Button" BasedOn="{StaticResource RoundedButton}">
                                <Setter Property="BorderBrush" Value="{DynamicResource BorderBrushColor}"/>
                            </Style>
                        </Grid.Resources>
                        <Grid.RowDefinitions>
                            <RowDefinition Height="*"/>
                        </Grid.RowDefinitions>

                        <Grid Grid.Row="0">
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="*"/>
                            </Grid.ColumnDefinitions>

                            <!-- Left Card: Features + Fixes -->
                            <Border Grid.Column="0" Margin="12,8,12,8" Background="{DynamicResource CardBrush}"
                                    CornerRadius="12" BorderThickness="2" BorderBrush="{DynamicResource BorderBrushColor}">
                                <ScrollViewer Style="{StaticResource CustomScrollViewer}" VerticalScrollBarVisibility="Auto">
                                    <StackPanel Margin="24">
                                        <!-- Features -->
                                        <TextBlock Text="Features" FontSize="18" FontWeight="Bold"
                                                   Foreground="{DynamicResource ForegroundBrush}" Margin="0,0,0,8"/>
                                        <StackPanel>
                                            <CheckBox Name="ChkFeatNetFxAll" Content="All .Net Framework (2,3,4)" Style="{StaticResource ToggleSwitchStyle}" Margin="0,0,0,8" FontSize="14"/>
                                            <CheckBox Name="ChkFeatHyperV" Content="HyperV Virtualization" Style="{StaticResource ToggleSwitchStyle}" Margin="0,0,0,8" FontSize="14"/>
                                            <CheckBox Name="ChkFeatLegacyMedia" Content="Legacy Media (WMP, DirectPlay)" Style="{StaticResource ToggleSwitchStyle}" Margin="0,0,0,8" FontSize="14"/>
                                            <CheckBox Name="ChkFeatNFS" Content="NFS - Network File System" Style="{StaticResource ToggleSwitchStyle}" Margin="0,0,0,8" FontSize="14"/>
                                            <CheckBox Name="ChkFeatEnableSearchSuggest" Content="Enable Search Box Web Suggestions in Registry (explorer restart)" Style="{StaticResource ToggleSwitchStyle}" Margin="0,0,0,8" FontSize="14"/>
                                            <CheckBox Name="ChkFeatDisableSearchSuggest" Content="Disable Search Box Web Suggestions in Registry (explorer restart)" Style="{StaticResource ToggleSwitchStyle}" Margin="0,0,0,8" FontSize="14"/>
                                            <CheckBox Name="ChkFeatEnableRegBackup" Content="Enable Daily Registry Backup Task 12:30am" Style="{StaticResource ToggleSwitchStyle}" Margin="0,0,0,8" FontSize="14"/>
                                            <CheckBox Name="ChkFeatEnableLegacyF8" Content="Enable Legacy F8 Boot Recovery" Style="{StaticResource ToggleSwitchStyle}" Margin="0,0,0,8" FontSize="14"/>
                                            <CheckBox Name="ChkFeatDisableLegacyF8" Content="Disable Legacy F8 Boot Recovery" Style="{StaticResource ToggleSwitchStyle}" Margin="0,0,0,8" FontSize="14"/>
                                            <CheckBox Name="ChkFeatWSL" Content="Windows Subsystem for Linux" Style="{StaticResource ToggleSwitchStyle}" Margin="0,0,0,8" FontSize="14"/>
                                            <CheckBox Name="ChkFeatSandbox" Content="Windows Sandbox" Style="{StaticResource ToggleSwitchStyle}" Margin="0,0,0,12" FontSize="14"/>
                                        </StackPanel>
                    <Button Name="BtnInstallFeatures" Content="Install Features"
                        Style="{StaticResource ConfigRoundedButton}" Height="44" Margin="0,4,0,16"/>

                                        <!-- Fixes -->
                                        <TextBlock Text="Fixes" FontSize="18" FontWeight="Bold"
                                                   Foreground="{DynamicResource ForegroundBrush}" Margin="0,12,0,8"/>
                                        <StackPanel>
                                            <Button Name="BtnSetupAutologin" Content="Set Up Autologin" Style="{StaticResource ConfigRoundedButton}" Height="44" Margin="0,0,0,8"/>
                                            <Button Name="BtnResetWindowsUpdate" Content="Reset Windows Update" Style="{StaticResource ConfigRoundedButton}" Height="44" Margin="0,0,0,8"/>
                                            <Button Name="BtnResetNetwork" Content="Reset Network" Style="{StaticResource ConfigRoundedButton}" Height="44" Margin="0,0,0,8"/>
                                            <Button Name="BtnSystemCorruptionScan" Content="System Corruption Scan" Style="{StaticResource ConfigRoundedButton}" Height="44" Margin="0,0,0,8"/>
                                            <Button Name="BtnWinGetReinstall" Content="WinGet Reinstall" Style="{StaticResource ConfigRoundedButton}" Height="44" Margin="0,0,0,8"/>
                                            <Button Name="BtnRemoveAdobeCC" Content="Remove Adobe Creative Cloud" Style="{StaticResource ConfigRoundedButton}" Height="44"/>
                                        </StackPanel>
                                    </StackPanel>
                                </ScrollViewer>
                            </Border>

                            <!-- Right Card: Quick Tweaks Actions -->
                            <Border Grid.Column="1" Margin="12,8,12,8" Background="{DynamicResource CardBrush}"
                                    CornerRadius="12" BorderThickness="2" BorderBrush="{DynamicResource BorderBrushColor}">
                                <Grid>
                                    <Grid.RowDefinitions>
                                        <RowDefinition Height="Auto"/>
                                        <RowDefinition Height="*"/>
                                    </Grid.RowDefinitions>

                                    <!-- Top buttons: single column, full-width -->
                                    <StackPanel Grid.Row="0" Margin="24,24,24,12">
                                        <Button Name="BtnSetRegTweaks" Content="Registry Tweaks" Style="{StaticResource ConfigRoundedButton}" Height="44" Margin="0,0,0,8"/>
                                        <Separator Background="Black" Height="1" Margin="0,6,0,6"/>
                                        <Button Name="BtnSetServiceTweaks" Content="Service Tweaks" Style="{StaticResource ConfigRoundedButton}" Height="44" Margin="0,0,0,8"/>
                                        <Separator Background="Black" Height="1" Margin="0,6,0,6"/>
                                        <Button Name="BtnRunDiskCleanup" Content="Run Disk Cleanup" Style="{StaticResource ConfigRoundedButton}" Height="44" Margin="0,0,0,8"/>
                                        <Button Name="BtnInstallUltimatePowerPlan" Content="Install Ultimate Power Plan" Style="{StaticResource ConfigRoundedButton}" Height="44"/>
                                    </StackPanel>

                                    <ScrollViewer Grid.Row="1" VerticalScrollBarVisibility="Auto">
                                        <StackPanel Margin="24,0,24,24">
                                            <TextBlock Text="One-click actions for common tweaks."
                                                       FontSize="12" Foreground="#999999" TextWrapping="Wrap"/>
                                            <Separator Margin="0,12,0,12"/>
                                            <TextBlock Text="Registry Tweaks: applies recommended registry performance and gaming settings."
                                                       FontSize="13" Foreground="{DynamicResource ForegroundBrush}" TextWrapping="Wrap" Margin="0,0,0,8"/>
                                            <TextBlock Text="Service Tweaks: sets recommended service startup types for performance and privacy."
                                                       FontSize="13" Foreground="{DynamicResource ForegroundBrush}" TextWrapping="Wrap"/>
                                        </StackPanel>
                                    </ScrollViewer>
                                </Grid>
                            </Border>
                        </Grid>
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
                            <ScrollViewer VerticalScrollBarVisibility="Auto" Background="{DynamicResource WindowBackgroundBrush}">
                                <RichTextBox Name="TxtLogs"
                                             IsReadOnly="True"
                                             FontFamily="Consolas"
                                             FontSize="14"
                                             Margin="10"
                                             Background="{DynamicResource WindowBackgroundBrush}"
                                             VerticalScrollBarVisibility="Auto"/>
                            </ScrollViewer>
                        </Border>

            <!-- Download Logs button removed -->
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
try {
    Add-Type -AssemblyName PresentationFramework
    $reader = New-Object System.Xml.XmlNodeReader ([xml]$xaml)
    $window = [Windows.Markup.XamlReader]::Load($reader)
} catch {
    Write-Host "XAML parse/load error: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.InnerException) {
        Write-Host "Inner: $($_.Exception.InnerException.Message)" -ForegroundColor Red
    }
    throw
}

# Startup activation prompt previously removed; no ContentRendered hook needed

# (noise.png usage removed)


# ===============================
# Startup: Force window to primary monitor and maximize
# ===============================
try {
    Add-Type -AssemblyName System.Windows.Forms | Out-Null
    $primary = [System.Windows.Forms.Screen]::PrimaryScreen
    if ($null -ne $primary) {
        # Place window on primary screen before maximizing
        $window.WindowStartupLocation = [System.Windows.WindowStartupLocation]::Manual
        $window.Left = $primary.WorkingArea.Left
        $window.Top = $primary.WorkingArea.Top
        $window.Width = $primary.WorkingArea.Width
        $window.Height = $primary.WorkingArea.Height
    }
    $window.WindowState = [System.Windows.WindowState]::Maximized
} catch {
    # Fallback: still try to maximize
    $window.WindowState = [System.Windows.WindowState]::Maximized
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
$BtnLogs              = $window.FindName("BtnLogs")
$BtnActivateWindows   = $window.FindName("BtnActivateWindows")

$PageHome             = $window.FindName("PageHome")
$PageInstall          = $window.FindName("PageInstall")
$PageTweaks           = $window.FindName("PageTweaks")
$PageConfig           = $window.FindName("PageConfig")
$PageLogs             = $window.FindName("PageLogs")

# PC Information Labels
$LblOS                = $window.FindName("LblOS")
$LblCPU               = $window.FindName("LblCPU")
$LblCPUDetails        = $window.FindName("LblCPUDetails")
$LblRAM               = $window.FindName("LblRAM")
$LblRAMDetails        = $window.FindName("LblRAMDetails")
$LblGPU               = $window.FindName("LblGPU")
$LblGPUDetails        = $window.FindName("LblGPUDetails")
$LblMotherboard       = $window.FindName("LblMotherboard")
$LblBIOS              = $window.FindName("LblBIOS")
$DiskList             = $window.FindName("DiskList")
$LblNetwork           = $window.FindName("LblNetwork")
$LblSound             = $window.FindName("LblSound")

# Advanced Info Labels
$LblRouterIP          = $window.FindName("LblRouterIP")
$LblIP                = $window.FindName("LblIP")
$LblMAC               = $window.FindName("LblMAC")
$LblHWID              = $window.FindName("LblHWID")
$LblPublicIP          = $window.FindName("LblPublicIP")

# Advanced PC Info Labels
$LblTPM               = $window.FindName("LblTPM")
$LblSecureBoot        = $window.FindName("LblSecureBoot")
$LblVirtualization    = $window.FindName("LblVirtualization")
$LblUEFI              = $window.FindName("LblUEFI")
$LblBitLocker         = $window.FindName("LblBitLocker")

$BtnToggleAdvanced    = $window.FindName("BtnToggleAdvanced")
$BtnSetRegTweaks      = $window.FindName("BtnSetRegTweaks")
$BtnSetServiceTweaks  = $window.FindName("BtnSetServiceTweaks")
$BtnRunDiskCleanup    = $window.FindName("BtnRunDiskCleanup")
$BtnInstallUltimatePowerPlan = $window.FindName("BtnInstallUltimatePowerPlan")
$TxtLogs              = $window.FindName("TxtLogs")
# (Removed) Download Logs button was deleted from XAML; no lookup needed
$BtnRunSelectedTweaks           = $window.FindName("BtnRunSelectedTweaks")
$BtnSelectAllTweaks             = $window.FindName("BtnSelectAllTweaks")
$BtnSelectRecommendedBasic      = $window.FindName("BtnSelectRecommendedBasic")
$BtnSelectRecommendedAdvanced   = $window.FindName("BtnSelectRecommendedAdvanced")

# Install Page Controls
$BtnGetInstalled      = $window.FindName("BtnGetInstalled")
$BtnClearSelection    = $window.FindName("BtnClearSelection")
$BtnUninstall         = $window.FindName("BtnUninstall")
$BtnInstallUpdate     = $window.FindName("BtnInstallUpdate")
$RbWinget             = $window.FindName("RbWinget")
$RbChocolatey         = $window.FindName("RbChocolatey")
## Touch variables to mark them as used for analyzers
$null = $BtnSetRegTweaks; $null = $BtnSetServiceTweaks; $null = $RbWinget; $null = $RbChocolatey
# Touch new Config-page controls
$null = $BtnInstallFeatures; $null = $ChkFeatNetFxAll; $null = $ChkFeatHyperV; $null = $ChkFeatLegacyMedia; $null = $ChkFeatNFS; 
$null = $ChkFeatEnableSearchSuggest; $null = $ChkFeatDisableSearchSuggest; $null = $ChkFeatEnableRegBackup; 
$null = $ChkFeatEnableLegacyF8; $null = $ChkFeatDisableLegacyF8; $null = $ChkFeatWSL; $null = $ChkFeatSandbox; 
$null = $BtnSetupAutologin; $null = $BtnResetWindowsUpdate; $null = $BtnResetNetwork; $null = $BtnSystemCorruptionScan; 
$null = $BtnWinGetReinstall; $null = $BtnRemoveAdobeCC

# Install Page App Buttons (Borders)
$BtnBrave             = $window.FindName("BtnBrave")
$BtnChrome            = $window.FindName("BtnChrome")
$BtnChromium          = $window.FindName("BtnChromium")
$BtnEdge              = $window.FindName("BtnEdge")
$BtnFalkon            = $window.FindName("BtnFalkon")
$BtnFirefox           = $window.FindName("BtnFirefox")
$BtnFirefoxESR        = $window.FindName("BtnFirefoxESR")
$BtnFloorp            = $window.FindName("BtnFloorp")
$BtnLibreWolf         = $window.FindName("BtnLibreWolf")
$BtnMullvadBrowser    = $window.FindName("BtnMullvadBrowser")
$BtnPaleMoon          = $window.FindName("BtnPaleMoon")
$BtnThorium           = $window.FindName("BtnThorium")
$BtnTorBrowser        = $window.FindName("BtnTorBrowser")
$BtnUngoogled         = $window.FindName("BtnUngoogled")
$BtnVivaldi           = $window.FindName("BtnVivaldi")
$BtnWaterfox          = $window.FindName("BtnWaterfox")
$BtnZenBrowser        = $window.FindName("BtnZenBrowser")
$BtnSteam             = $window.FindName("BtnSteam")
$BtnEpicGames         = $window.FindName("BtnEpicGames")
$BtnEAApp             = $window.FindName("BtnEAApp")
$BtnUbisoft           = $window.FindName("BtnUbisoft")
$BtnGOG               = $window.FindName("BtnGOG")
$BtnProtonVPN         = $window.FindName("BtnProtonVPN")
$BtnProtonMail        = $window.FindName("BtnProtonMail")
$BtnProtonDrive       = $window.FindName("BtnProtonDrive")
$BtnProtonPass        = $window.FindName("BtnProtonPass")
$BtnAegisub           = $window.FindName("BtnAegisub")
$BtnAnaconda          = $window.FindName("BtnAnaconda")
$BtnClink             = $window.FindName("BtnClink")
$BtnCMake             = $window.FindName("BtnCMake")
$BtnDaxStudio         = $window.FindName("BtnDaxStudio")
$BtnDocker            = $window.FindName("BtnDocker")
$BtnFNM               = $window.FindName("BtnFNM")
$BtnFork              = $window.FindName("BtnFork")
$BtnGit               = $window.FindName("BtnGit")
$BtnGitButler         = $window.FindName("BtnGitButler")
$BtnGitExtensions     = $window.FindName("BtnGitExtensions")
$BtnGitHubCLI         = $window.FindName("BtnGitHubCLI")
$BtnGitHubDesktop     = $window.FindName("BtnGitHubDesktop")
$BtnGitify            = $window.FindName("BtnGitify")
$BtnGitKraken         = $window.FindName("BtnGitKraken")
$BtnGodot             = $window.FindName("BtnGodot")
$BtnGo                = $window.FindName("BtnGo")
$BtnHelix             = $window.FindName("BtnHelix")
$BtnCorretto11        = $window.FindName("BtnCorretto11")
$BtnCorretto17        = $window.FindName("BtnCorretto17")
$BtnCorretto21        = $window.FindName("BtnCorretto21")
$BtnCorretto8         = $window.FindName("BtnCorretto8")
$BtnJetbrainsToolbox  = $window.FindName("BtnJetbrainsToolbox")
$BtnLazygit           = $window.FindName("BtnLazygit")
$BtnMiniconda         = $window.FindName("BtnMiniconda")
$BtnMu                = $window.FindName("BtnMu")
$BtnNeovim            = $window.FindName("BtnNeovim")
$BtnNodeJS            = $window.FindName("BtnNodeJS")
$BtnNodeJSLTS         = $window.FindName("BtnNodeJSLTS")
$BtnNVM               = $window.FindName("BtnNVM")
$BtnPixi              = $window.FindName("BtnPixi")
$BtnOhMyPosh          = $window.FindName("BtnOhMyPosh")
$BtnPostman           = $window.FindName("BtnPostman")
$BtnPulsar            = $window.FindName("BtnPulsar")
$BtnPyenv             = $window.FindName("BtnPyenv")
$BtnPython            = $window.FindName("BtnPython")
$BtnRust              = $window.FindName("BtnRust")
$BtnStarship          = $window.FindName("BtnStarship")
$BtnSublimeMerge      = $window.FindName("BtnSublimeMerge")
$BtnSublimeText       = $window.FindName("BtnSublimeText")
$BtnSwift             = $window.FindName("BtnSwift")
$BtnTemurin           = $window.FindName("BtnTemurin")
$BtnThonny            = $window.FindName("BtnThonny")
$BtnUnity             = $window.FindName("BtnUnity")
$BtnVagrant           = $window.FindName("BtnVagrant")
$BtnVisualStudio2022  = $window.FindName("BtnVisualStudio2022")
$BtnVSCode            = $window.FindName("BtnVSCode")
$BtnVSCodium          = $window.FindName("BtnVSCodium")
$BtnWezterm           = $window.FindName("BtnWezterm")
$BtnYarn              = $window.FindName("BtnYarn")
$BtnDiscord           = $window.FindName("BtnDiscord")
$BtnSpotify           = $window.FindName("BtnSpotify")
$BtnVLC               = $window.FindName("BtnVLC")
$Btn7Zip              = $window.FindName("Btn7Zip")
$BtnNotepadPlusPlus   = $window.FindName("BtnNotepadPlusPlus")
$BtnOBS               = $window.FindName("BtnOBS")

# Initialize reliable MDL2 glyphs for specific buttons
try {
    if ($null -ne $BtnToggleTheme) {
        $BtnToggleTheme.FontFamily = "Segoe MDL2 Assets"
        # Start in dark mode, show Sunny (switch to light)
        $BtnToggleTheme.Content = [char]0xE708
    }
    if ($null -ne $BtnToggleAdvanced) {
        $BtnToggleAdvanced.FontFamily = "Segoe MDL2 Assets"
        # Hidden by default, show ChevronDown
        $BtnToggleAdvanced.Content = [char]0xE70D
    }
} catch { }

# Track selected apps
$script:SelectedApps = @{}
$BtnSetRecommended    = $window.FindName("BtnSetRecommended")
# Config page - new controls
$BtnInstallFeatures   = $window.FindName("BtnInstallFeatures")
$ChkFeatNetFxAll      = $window.FindName("ChkFeatNetFxAll")
$ChkFeatHyperV        = $window.FindName("ChkFeatHyperV")
$ChkFeatLegacyMedia   = $window.FindName("ChkFeatLegacyMedia")
$ChkFeatNFS           = $window.FindName("ChkFeatNFS")
$ChkFeatEnableSearchSuggest  = $window.FindName("ChkFeatEnableSearchSuggest")
$ChkFeatDisableSearchSuggest = $window.FindName("ChkFeatDisableSearchSuggest")
$ChkFeatEnableRegBackup      = $window.FindName("ChkFeatEnableRegBackup")
$ChkFeatEnableLegacyF8       = $window.FindName("ChkFeatEnableLegacyF8")
$ChkFeatDisableLegacyF8      = $window.FindName("ChkFeatDisableLegacyF8")
$ChkFeatWSL           = $window.FindName("ChkFeatWSL")
$ChkFeatSandbox       = $window.FindName("ChkFeatSandbox")
$BtnSetupAutologin    = $window.FindName("BtnSetupAutologin")
$BtnResetWindowsUpdate= $window.FindName("BtnResetWindowsUpdate")
$BtnResetNetwork      = $window.FindName("BtnResetNetwork")
$BtnSystemCorruptionScan = $window.FindName("BtnSystemCorruptionScan")
$BtnWinGetReinstall   = $window.FindName("BtnWinGetReinstall")
$BtnRemoveAdobeCC     = $window.FindName("BtnRemoveAdobeCC")

# Advanced Tweaks Checkboxes
$ChkDisableIPv6                         = $window.FindName("ChkDisableIPv6")
$ChkBlockAdobeNetwork                   = $window.FindName("ChkBlockAdobeNetwork")
$ChkDebloatAdobe                        = $window.FindName("ChkDebloatAdobe")
$ChkPreferIPv4                          = $window.FindName("ChkPreferIPv4")
$ChkDisableTeredo                       = $window.FindName("ChkDisableTeredo")
$ChkDisableBackgroundApps               = $window.FindName("ChkDisableBackgroundApps")
$ChkDisableFullscreenOptimizations      = $window.FindName("ChkDisableFullscreenOptimizations")
$ChkDisableCopilot                      = $window.FindName("ChkDisableCopilot")
$ChkDisableIntelMM                      = $window.FindName("ChkDisableIntelMM")
$ChkDisableNotificationTray             = $window.FindName("ChkDisableNotificationTray")
$ChkDisableWPBT                         = $window.FindName("ChkDisableWPBT")
$ChkSetDisplayPerformance               = $window.FindName("ChkSetDisplayPerformance")
$ChkSetClassicRightClick                = $window.FindName("ChkSetClassicRightClick")
$ChkSetTimeUTC                          = $window.FindName("ChkSetTimeUTC")
$ChkRemoveMSStoreApps                   = $window.FindName("ChkRemoveMSStoreApps")
$ChkRemoveHomeFromExplorer              = $window.FindName("ChkRemoveHomeFromExplorer")
$ChkRemoveGalleryFromExplorer           = $window.FindName("ChkRemoveGalleryFromExplorer")
$ChkRemoveOneDrive                      = $window.FindName("ChkRemoveOneDrive")
$ChkBlockRazerSoftware                  = $window.FindName("ChkBlockRazerSoftware")
$ChkDeleteTempFiles                     = $window.FindName("ChkDeleteTempFiles")
$ChkDisableConsumerFeatures             = $window.FindName("ChkDisableConsumerFeatures")
$ChkDisableTelemetry                    = $window.FindName("ChkDisableTelemetry")
$ChkDisableActivityHistory              = $window.FindName("ChkDisableActivityHistory")
$ChkDisableExplorerFolderDiscovery      = $window.FindName("ChkDisableExplorerFolderDiscovery")
$ChkDisableGameDVR                      = $window.FindName("ChkDisableGameDVR")
$ChkDisableHibernation                  = $window.FindName("ChkDisableHibernation")
$ChkDisableHomegroup                    = $window.FindName("ChkDisableHomegroup")
$ChkDisableLocationTracking             = $window.FindName("ChkDisableLocationTracking")
$ChkDisableStorageSense                 = $window.FindName("ChkDisableStorageSense")
$ChkDisableWifiSense                    = $window.FindName("ChkDisableWifiSense")
$ChkEnableEndTaskRightClick             = $window.FindName("ChkEnableEndTaskRightClick")
$ChkSetTerminalDefault                  = $window.FindName("ChkSetTerminalDefault")
$ChkDisablePS7Telemetry                 = $window.FindName("ChkDisablePS7Telemetry")
$ChkDisableRecall                       = $window.FindName("ChkDisableRecall")
$ChkSetHibernationDefault               = $window.FindName("ChkSetHibernationDefault")
$ChkDebloatBrave                        = $window.FindName("ChkDebloatBrave")
$ChkDebloatEdge                         = $window.FindName("ChkDebloatEdge")

# ===============================
# Config helpers (features + fixes)
# ===============================
function Enable-OptionalFeature {
    param(
        [Parameter(Mandatory)] [string]$Name
    )
    try {
        Write-Log "Enabling Windows feature: $Name"
        Invoke-ExternalCommand "dism /online /enable-feature /featurename:$Name /all /norestart"
    } catch {
        Write-Log "[ERROR] Failed to enable feature ${Name}: $_"
    }
}

function Disable-OptionalFeature {
    param(
        [Parameter(Mandatory)] [string]$Name
    )
    try {
        Write-Log "Disabling Windows feature: $Name"
        Invoke-ExternalCommand "dism /online /disable-feature /featurename:$Name /norestart"
    } catch {
        Write-Log "[ERROR] Failed to disable feature ${Name}: $_"
    }
}

function Install-SelectedFeatures {
    if (-not (Test-IsAdministrator)) {
        [System.Windows.MessageBox]::Show("This action requires administrator privileges.", "Admin required", "OK", "Warning") | Out-Null
        return
    }

    $changes = @()

    # .NET Framework (2,3,4)
    if ($ChkFeatNetFxAll.IsChecked) {
        Enable-OptionalFeature -Name "NetFx3"
        # NetFx4 is built-in on Win10/11; ensure client package components if togglable
        $changes += ".NET Framework (2,3,4)"
    }

    # Hyper-V stack
    if ($ChkFeatHyperV.IsChecked) {
        Enable-OptionalFeature -Name "Microsoft-Hyper-V-All"
        $changes += "Hyper-V"
    }

    # Legacy Media (WMP, DirectPlay)
    if ($ChkFeatLegacyMedia.IsChecked) {
        Enable-OptionalFeature -Name "WindowsMediaPlayer"
        Enable-OptionalFeature -Name "LegacyComponents"
        Enable-OptionalFeature -Name "DirectPlay"
        $changes += "Legacy Media"
    }

    # NFS Client
    if ($ChkFeatNFS.IsChecked) {
        Enable-OptionalFeature -Name "ServicesForNFS-ClientOnly"
        $changes += "NFS Client"
    }

    # Search Box Web Suggestions
    # Note: If both enable and disable are checked, 'Disable' wins to be explicit.
    if ($ChkFeatEnableSearchSuggest.IsChecked -and -not $ChkFeatDisableSearchSuggest.IsChecked) {
        try {
            Set-RegistryValue -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer" -Name "DisableSearchBoxSuggestions" -Type DWord -Value 0
        } catch {}
        try {
            Set-RegistryValue -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" -Name "BingSearchEnabled" -Type DWord -Value 1
        } catch {}
        Restart-Explorer
        $changes += "Enable Search suggestions"
    }
    if ($ChkFeatDisableSearchSuggest.IsChecked) {
        try {
            Set-RegistryValue -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer" -Name "DisableSearchBoxSuggestions" -Type DWord -Value 1
        } catch {}
        try {
            Set-RegistryValue -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" -Name "BingSearchEnabled" -Type DWord -Value 0
        } catch {}
        Restart-Explorer
        $changes += "Disable Search suggestions"
    }

    # Registry backup daily at 12:30 AM
    if ($ChkFeatEnableRegBackup.IsChecked) {
        try {
            $action  = New-ScheduledTaskAction -Execute "schtasks.exe" -Argument "/Run /TN \"\\Microsoft\\Windows\\Registry\\RegIdleBackup\""
            $trigger = New-ScheduledTaskTrigger -Daily -At 00:30
            $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -RunLevel Highest -LogonType ServiceAccount
            Register-ScheduledTask -TaskName "DailyRegIdleBackup" -Action $action -Trigger $trigger -Principal $principal -Force | Out-Null
            Write-Log "Scheduled task 'DailyRegIdleBackup' created to run RegIdleBackup at 12:30 AM daily."
        } catch {
            Write-Log "[ERROR] Failed to create DailyRegIdleBackup task: $_"
        }
    }

    # Legacy F8 boot recovery
    if ($ChkFeatEnableLegacyF8.IsChecked -and -not $ChkFeatDisableLegacyF8.IsChecked) {
        try { Invoke-ExternalCommand "bcdedit /set {current} bootmenupolicy legacy" } catch {}
        $changes += "Enable Legacy F8"
    }
    if ($ChkFeatDisableLegacyF8.IsChecked) {
        try { Invoke-ExternalCommand "bcdedit /set {current} bootmenupolicy standard" } catch {}
        $changes += "Disable Legacy F8"
    }

    # WSL & VM Platform
    if ($ChkFeatWSL.IsChecked) {
        Enable-OptionalFeature -Name "Microsoft-Windows-Subsystem-Linux"
        Enable-OptionalFeature -Name "VirtualMachinePlatform"
        $changes += "WSL + VM Platform"
    }

    # Windows Sandbox
    if ($ChkFeatSandbox.IsChecked) {
        Enable-OptionalFeature -Name "Containers-DisposableClientVM"
        $changes += "Windows Sandbox"
    }

    if ($changes.Count -gt 0) {
        Write-Log ("[Features] Applied: " + ($changes -join ", "))
        [System.Windows.MessageBox]::Show("Selected features applied. Some features may require a restart to take effect.", "Features", "OK", "Information") | Out-Null
    } else {
        [System.Windows.MessageBox]::Show("No features selected.", "Features", "OK", "Information") | Out-Null
    }
}

function Start-AutologinSetup {
    try {
        Write-Log "Launching netplwiz for autologin setup"
        Start-Process -FilePath "netplwiz.exe" -Verb runAs
    } catch {
        Write-Log "[ERROR] Failed to launch netplwiz: $_"
    }
}

function Reset-WindowsUpdate {
    if (-not (Test-IsAdministrator)) {
        [System.Windows.MessageBox]::Show("Resetting Windows Update requires administrator privileges.", "Admin required", "OK", "Warning") | Out-Null
        return
    }
    try {
        Write-Log "Resetting Windows Update components..."
        Stop-Service -Name wuauserv,bits,cryptsvc,msiserver -Force -ErrorAction SilentlyContinue
        Rename-Item -Path "$env:SystemRoot\SoftwareDistribution" -NewName "SoftwareDistribution.old" -ErrorAction SilentlyContinue
        Rename-Item -Path "$env:SystemRoot\System32\catroot2" -NewName "catroot2.old" -ErrorAction SilentlyContinue
        Start-Service -Name wuauserv,bits,cryptsvc,msiserver -ErrorAction SilentlyContinue
        Write-Log "Windows Update components reset complete."
    } catch {
        Write-Log "[ERROR] Windows Update reset failed: $_"
    }
}

function Reset-NetworkStack {
    if (-not (Test-IsAdministrator)) {
        [System.Windows.MessageBox]::Show("Network reset requires administrator privileges.", "Admin required", "OK", "Warning") | Out-Null
        return
    }
    try {
        Write-Log "Resetting network stack (winsock/ip) and flushing DNS..."
        Invoke-ExternalCommand "netsh winsock reset"
        Invoke-ExternalCommand "netsh int ip reset"
        Invoke-ExternalCommand "ipconfig /flushdns"
        Write-Log "Network stack reset complete. A restart may be required."
    } catch {
        Write-Log "[ERROR] Network reset failed: $_"
    }
}

function Invoke-SystemCorruptionScan {
    if (-not (Test-IsAdministrator)) {
        [System.Windows.MessageBox]::Show("This operation requires administrator privileges.", "Admin required", "OK", "Warning") | Out-Null
        return
    }
    try {
        Write-Log "Running DISM RestoreHealth... (this can take a while)"
        Invoke-ExternalCommand "dism /online /cleanup-image /restorehealth"
        Write-Log "Running SFC /scannow..."
        Invoke-ExternalCommand "sfc /scannow"
        Write-Log "System corruption scan completed."
    } catch {
        Write-Log "[ERROR] System corruption scan failed: $_"
    }
}

function Repair-WinGet {
    if (-not (Test-IsAdministrator)) {
        [System.Windows.MessageBox]::Show("Reinstalling WinGet requires administrator privileges.", "Admin required", "OK", "Warning") | Out-Null
        return
    }
    try {
        Write-Log "Attempting to repair WinGet sources..."
        Invoke-ExternalCommand "winget source reset --force"
        Invoke-ExternalCommand "winget source update"
    } catch {
        Write-Log "[WARN] Winget source repair commands failed or winget not available: $_"
    }
    try {
        Write-Log "Re-registering Desktop App Installer..."
        Get-AppxPackage -AllUsers Microsoft.DesktopAppInstaller | ForEach-Object {
            Add-AppxPackage -DisableDevelopmentMode -Register (Join-Path $_.InstallLocation "AppxManifest.xml") -ForceApplicationShutdown
        }
        Write-Log "Desktop App Installer re-registered."
    } catch {
        Write-Log "[ERROR] Failed to re-register App Installer: $_"
    }
}

function Remove-AdobeCreativeCloud {
    if (-not (Test-IsAdministrator)) {
        [System.Windows.MessageBox]::Show("Removing Adobe Creative Cloud requires administrator privileges.", "Admin required", "OK", "Warning") | Out-Null
        return
    }
    $removed = $false
    try {
        Write-Log "Trying to uninstall Adobe Creative Cloud via WinGet..."
        Invoke-ExternalCommand "winget uninstall --id Adobe.CreativeCloud --exact --silent --time-limit 1800"
        $removed = $true
    } catch {
        Write-Log "[INFO] WinGet uninstall failed or Adobe CC not found: $_"
    }
    if (-not $removed) {
        $uninstallers = @(
            "C:\\Program Files (x86)\\Adobe\\Adobe Creative Cloud\\Utils\\Creative Cloud Uninstaller.exe",
            "C:\\Program Files\\Adobe\\Adobe Creative Cloud\\Utils\\Creative Cloud Uninstaller.exe"
        )
        foreach ($path in $uninstallers) {
            if (Test-Path $path) {
                try {
                    Write-Log "Running Adobe Creative Cloud uninstaller at: $path"
                    Start-Process -FilePath $path -ArgumentList "/silent" -Wait -Verb runAs
                    $removed = $true
                    break
                } catch {
                    Write-Log "[ERROR] Failed running uninstaller: $_"
                }
            }
        }
    }
    if ($removed) {
        Write-Log "Adobe Creative Cloud removal attempted. Please verify in Apps & Features."
    } else {
        Write-Log "[WARN] Adobe Creative Cloud uninstaller not found and WinGet uninstall did not complete."
    }
}

# Preferences
$ChkPrefDarkTheme                = $window.FindName("ChkPrefDarkTheme")
$ChkPrefBingSearch               = $window.FindName("ChkPrefBingSearch")
$ChkPrefNumLock                  = $window.FindName("ChkPrefNumLock")
$ChkPrefVerboseLogon             = $window.FindName("ChkPrefVerboseLogon")
$ChkPrefStartRecommendations     = $window.FindName("ChkPrefStartRecommendations")
$ChkPrefSettingsHomePage         = $window.FindName("ChkPrefSettingsHomePage")
$ChkPrefSnapWindow               = $window.FindName("ChkPrefSnapWindow")
$ChkPrefSnapAssistFlyout         = $window.FindName("ChkPrefSnapAssistFlyout")
$ChkPrefSnapAssistSuggestion     = $window.FindName("ChkPrefSnapAssistSuggestion")
$ChkPrefMouseAcceleration        = $window.FindName("ChkPrefMouseAcceleration")
$ChkPrefStickyKeys               = $window.FindName("ChkPrefStickyKeys")
$ChkPrefShowHiddenFiles          = $window.FindName("ChkPrefShowHiddenFiles")
$ChkPrefShowFileExtensions       = $window.FindName("ChkPrefShowFileExtensions")
$ChkPrefSearchButton             = $window.FindName("ChkPrefSearchButton")
$ChkPrefTaskViewButton           = $window.FindName("ChkPrefTaskViewButton")
$ChkPrefCenterTaskbar            = $window.FindName("ChkPrefCenterTaskbar")
$ChkPrefWidgetsButton            = $window.FindName("ChkPrefWidgetsButton")
$ChkPrefDetailedBSoD             = $window.FindName("ChkPrefDetailedBSoD")
$ChkPrefS3Sleep                  = $window.FindName("ChkPrefS3Sleep")
$ChkPrefDesktopIcons             = $window.FindName("ChkPrefDesktopIcons")

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
function Get-ParentObject {
    param([System.Windows.DependencyObject]$obj)
    if ($null -eq $obj) { return $null }
    # Prefer Visual tree when possible, otherwise fall back to Logical tree
    if ($obj -is [System.Windows.Media.Visual] -or $obj -is [System.Windows.Media.Media3D.Visual3D]) {
        return [System.Windows.Media.VisualTreeHelper]::GetParent($obj)
    } else {
        try { return [System.Windows.LogicalTreeHelper]::GetParent($obj) } catch { return $null }
    }
}

function Test-WithinInteractiveControl {
    param([System.Windows.DependencyObject]$start)
    $current = $start
    while ($null -ne $current) {
        if ($current -is [System.Windows.Controls.Primitives.ButtonBase] -or
            $current -is [System.Windows.Controls.TextBox] -or
            $current -is [System.Windows.Controls.Primitives.ToggleButton] -or
            $current -is [System.Windows.Controls.ComboBox] -or
            $current -is [System.Windows.Controls.ListBoxItem]) {
            return $true
        }
        $current = Get-ParentObject -obj $current
    }
    return $false
}

# Drag window by holding top bar (but not on buttons or other interactive controls)
if ($null -ne $DragArea) {
    $DragArea.Add_PreviewMouseLeftButtonDown({
        param($s, $e)
        try {
            $depObj = $e.OriginalSource -as [System.Windows.DependencyObject]
            if ($null -ne $depObj) {
                if (Test-WithinInteractiveControl -start $depObj) { return }
            }
            # Perform drag
            $window.DragMove()
            $e.Handled = $true
        } catch {
            # DragMove can fail in certain scenarios, silently ignore
        }
    })
}

# ===============================================================================================================================
#                                    Old Mouse Acceleration code removed - now handled in Preferences section
# ===============================================================================================================================



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
    $BtnMaximize.Content = "[ ]"
    } else {
        $window.WindowState = [System.Windows.WindowState]::Maximized 
    $BtnMaximize.Content = "[]"
    }
})

# ===============================
# In-memory Logging (no file until user saves)
# ===============================
if (-not $global:LogEntries) { $global:LogEntries = New-Object System.Collections.Generic.List[string] }

function Write-Log($message) {
    try {
        $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        $line = "[$timestamp] $message"
        $global:LogEntries.Add($line)
        # Cap size to avoid unbounded memory (keep last 5000 lines)
        if ($global:LogEntries.Count -gt 5000) {
            $removeCount = $global:LogEntries.Count - 5000
            $null = $global:LogEntries.RemoveRange(0, $removeCount)
        }
    } catch {
        # Never crash on logging
    }
}

# ===============================
# Logs Button Logic
# ===============================
$BtnLogs.Add_Click({
    Show-Page $PageLogs
    $TxtLogs.Document.Blocks.Clear()
    $paragraph = New-Object System.Windows.Documents.Paragraph
    $lines = $global:LogEntries
    if ($null -ne $lines -and $lines.Count -gt 0) {
        foreach ($line in $lines) {
            $run = New-Object System.Windows.Documents.Run
            $run.Text = $line + "`n"
            if ($line -match '\b(SUCCESS|SUCCESSFULLY|SUCCESSFUL|ENABLED|COMPLETED|OK|DISABLED|DISSABLED)\b') {
                $run.Foreground = [System.Windows.Media.Brushes]::LimeGreen
            } elseif ($line -match '\b(ERROR|FAILED|FAILURE|EXCEPTION|CRITICAL)\b') {
                $run.Foreground = [System.Windows.Media.Brushes]::Red
            } elseif ($line -match '\b(WARNING|WARN)\b') {
                $run.Foreground = [System.Windows.Media.Brushes]::Orange
            } else {
                $run.Foreground = $window.Resources["ForegroundBrush"]
            }
            $paragraph.Inlines.Add($run)
        }
    } else {
        $run = New-Object System.Windows.Documents.Run
        $run.Text = "No logs yet."
        $paragraph.Inlines.Add($run)
    }
    $TxtLogs.Document.Blocks.Add($paragraph)
})

# (Removed) Download Logs handler – feature removed

# ===============================
# Populate System Info
# ===============================
try {
    $os      = Get-CimInstance Win32_OperatingSystem
    $cpu     = Get-CimInstance Win32_Processor
    $ramModules = Get-CimInstance Win32_PhysicalMemory
    $ramTotal = ($ramModules | Measure-Object -Property Capacity -Sum).Sum / 1GB
    $gpu     = Get-CimInstance Win32_VideoController | Select-Object -First 1
    $mb      = Get-CimInstance Win32_BaseBoard
    $bios    = Get-CimInstance Win32_BIOS
    $disk    = Get-CimInstance Win32_DiskDrive | Select-Object -First 1
    $net     = Get-CimInstance Win32_NetworkAdapter | Where-Object { $_.NetEnabled } | Select-Object -First 1
    $sound   = Get-CimInstance Win32_SoundDevice | Select-Object -First 1

    # OS Info
    $LblOS.Text = "OS: $($os.Caption) (Build $($os.BuildNumber))"
    
    # CPU Info (Always visible)
    $LblCPU.Text = "CPU: $($cpu.Name)"
    $LblCPUDetails.Text = "- $($cpu.NumberOfCores) Cores / $($cpu.NumberOfLogicalProcessors) Threads @ $($cpu.MaxClockSpeed) MHz"
    
    # RAM Info (Always visible)
    $ramSpeed = ($ramModules | Select-Object -First 1).Speed
    $ramSlots = $ramModules.Count
    $LblRAM.Text = "RAM: {0:N2} GB" -f $ramTotal
    $LblRAMDetails.Text = "- $ramSpeed MHz - $ramSlots Slot(s) Used"
    
    # GPU Info (Always visible)
    $gpuVRAM = [math]::Round($gpu.AdapterRAM/1GB,2)
    $gpuDriver = $gpu.DriverVersion
    $LblGPU.Text = "GPU: $($gpu.Name)"
    $LblGPUDetails.Text = "- $gpuVRAM GB VRAM - Driver: $gpuDriver"
    
    # Motherboard
    $LblMotherboard.Text = "Motherboard: $($mb.Manufacturer) $($mb.Product)"
    
    # BIOS
    $LblBIOS.Text = "BIOS: $($bios.Manufacturer) $($bios.SMBIOSBIOSVersion)"
    
    # All Disks (Get all physical drives)
    $DiskList.Children.Clear()
    $allDisks = Get-CimInstance Win32_DiskDrive
    $diskNumber = 1
    foreach ($disk in $allDisks) {
        $diskSize = [math]::Round($disk.Size/1GB,0)
        $diskType = if ($disk.MediaType -match "SSD") { "SSD" } 
                    elseif ($disk.MediaType -match "Fixed") { "HDD" } 
                    elseif ($disk.MediaType -match "Removable") { "Removable" }
                    else { "Unknown" }
        
        $diskTextBlock = New-Object System.Windows.Controls.TextBlock
    $diskTextBlock.Text = "- Disk $diskNumber`: $diskSize GB $diskType"
        $diskTextBlock.FontSize = 14
        $grayBrush = New-Object System.Windows.Media.SolidColorBrush([System.Windows.Media.Color]::FromRgb(176, 176, 176))
        $diskTextBlock.Foreground = $grayBrush
        $diskTextBlock.Margin = "0,2"
        $DiskList.Children.Add($diskTextBlock) | Out-Null
        $diskNumber++
    }
    
    # Network
    $LblNetwork.Text = "Network: $($net.Name)"
    
    # Sound
    $LblSound.Text = "Sound: $($sound.Name)"

    # Advanced Info (Network/Security)
    $LblRouterIP.Text = "Router IP: " + ((Get-NetRoute -DestinationPrefix "0.0.0.0/0").NextHop | Select-Object -First 1)
    $LblIP.Text       = "Local IP: " + (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -notlike "*Loopback*" } | Select-Object -First 1).IPAddress
    $LblMAC.Text      = "MAC Address: " + (Get-NetAdapter | Where-Object Status -eq "Up" | Select-Object -First 1).MacAddress
    $LblHWID.Text     = "HWID: " + (Get-CimInstance Win32_ComputerSystemProduct).UUID

    try {
        $LblPublicIP.Text = "Public IP: " + (Invoke-RestMethod -Uri "https://api.ipify.org" -TimeoutSec 3)
    } catch {
        $LblPublicIP.Text = "Public IP: [Offline]"
    }
    
    # Advanced PC Info (Security Features)
    # TPM Version
    try {
        $tpm = Get-CimInstance -Namespace "Root\CIMv2\Security\MicrosoftTpm" -ClassName Win32_Tpm -ErrorAction Stop
        if ($tpm.IsEnabled_InitialValue) {
            $tpmVersion = $tpm.SpecVersion
            $LblTPM.Text = "TPM: Enabled (Version $tpmVersion)"
        } else {
            $LblTPM.Text = "TPM: Disabled"
        }
    } catch {
        $LblTPM.Text = "TPM: Not Available"
    }
    
    # Secure Boot
    try {
        $secureBoot = Confirm-SecureBootUEFI
    $LblSecureBoot.Text = if ($secureBoot) { "Secure Boot: Enabled" } else { "Secure Boot: Disabled" }
    } catch {
        $LblSecureBoot.Text = "Secure Boot: Not Supported"
    }
    
    # Virtualization
    try {
        $virtEnabled = (Get-CimInstance Win32_Processor).VirtualizationFirmwareEnabled
    $LblVirtualization.Text = if ($virtEnabled) { "Virtualization: Enabled" } else { "Virtualization: Disabled" }
    } catch {
        $LblVirtualization.Text = "Virtualization: Unknown"
    }
    
    # UEFI/Legacy
    try {
        $bootMode = $env:firmware_type
        if (-not $bootMode) {
            $bootMode = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control" -Name "PEFirmwareType" -ErrorAction SilentlyContinue).PEFirmwareType
            $bootMode = if ($bootMode -eq 2) { "UEFI" } elseif ($bootMode -eq 1) { "Legacy" } else { "Unknown" }
        }
        $LblUEFI.Text = "Boot Mode: $bootMode"
    } catch {
        $LblUEFI.Text = "Boot Mode: Unknown"
    }
    
    # BitLocker Status
    try {
        $bitlockerVolumes = Get-BitLockerVolume -ErrorAction SilentlyContinue | Where-Object { $_.VolumeType -eq "OperatingSystem" }
        if ($bitlockerVolumes) {
            $protection = $bitlockerVolumes.ProtectionStatus
            $LblBitLocker.Text = if ($protection -eq "On") { "BitLocker: Enabled" } else { "BitLocker: Disabled" }
        } else {
            $LblBitLocker.Text = "BitLocker: Not Available"
        }
    } catch {
        $LblBitLocker.Text = "BitLocker: Not Available"
    }
    
} catch {
    Write-Host "Error fetching system info: $_" -ForegroundColor Red
}

# ===============================
# Advanced Info Toggle Logic
# ===============================
$global:AdvancedInfoState = "hidden"  # States: hidden -> revealed -> hidden
$AdvancedLabels = @($LblRouterIP, $LblIP, $LblMAC, $LblHWID, $LblPublicIP)
$OriginalTexts = @{}

# Save original texts & mask them initially with asterisks
foreach ($lbl in $AdvancedLabels) {
    $OriginalTexts[$lbl.Name] = $lbl.Text
    $parts = $lbl.Text -split ": ", 2
    if ($parts.Count -ge 2) {
        $lbl.Text = $parts[0] + ": " + ("*" * $parts[1].Length)
    }
}

$BtnToggleAdvanced.Add_Click({
    if ($global:AdvancedInfoState -eq "hidden") {
        # First click: Show the info
        foreach ($lbl in $AdvancedLabels) {
            $lbl.Text = $OriginalTexts[$lbl.Name]
        }
    # Advanced info revealed => show ChevronUp
    $BtnToggleAdvanced.FontFamily = "Segoe MDL2 Assets"
    $BtnToggleAdvanced.Content = [char]0xE70E
        $global:AdvancedInfoState = "revealed"
    } else {
        # Subsequent clicks: Toggle between hidden and revealed
        if ($global:AdvancedInfoState -eq "revealed") {
            # Hide the info with asterisks
            foreach ($lbl in $AdvancedLabels) {
                $parts = $OriginalTexts[$lbl.Name] -split ": ", 2
                if ($parts.Count -ge 2) {
                    $lbl.Text = $parts[0] + ": " + ("*" * $parts[1].Length)
                }
            }
            # Advanced info hidden => show ChevronDown
            $BtnToggleAdvanced.FontFamily = "Segoe MDL2 Assets"
            $BtnToggleAdvanced.Content = [char]0xE70D
            $global:AdvancedInfoState = "hidden"
        }
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
            
            $BtnToggleTheme.FontFamily = "Segoe MDL2 Assets"
            $BtnToggleTheme.Content = [char]0xE28F  # ClearNight (switch to dark)
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
            
            $BtnToggleTheme.FontFamily = "Segoe MDL2 Assets"
            $BtnToggleTheme.Content = [char]0xE708  # Sunny (switch to light)
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
    foreach ($p in @($PageHome,$PageInstall,$PageTweaks,$PageConfig,$PageLogs)) {
        $p.Visibility = "Collapsed"
    }
    $page.Visibility = "Visible"
}

## Removed: Get-PageTemplate helper (unused)

$BtnHome.Add_Click({ Show-Page $PageHome })
$BtnInstall.Add_Click({ Show-Page $PageInstall })
$BtnTweaks.Add_Click({ Show-Page $PageTweaks })
$BtnConfig.Add_Click({ Show-Page $PageConfig })
$BtnLogs.Add_Click({ Show-Page $PageLogs })
# Run Disk Cleanup button
if ($null -ne $BtnRunDiskCleanup) {
$BtnRunDiskCleanup.Add_Click({
    try {
    Set-DiskCleanupRecommendations -SageProfile 1
        Start-DiskCleanup
    } catch {
        Write-Host "[ERROR] Run Disk Cleanup failed: $_" -ForegroundColor Red
        Write-Log "[ERROR] Run Disk Cleanup failed: $_"
    }
})
}

# Activate Windows Button
$BtnActivateWindows.Add_Click({
    $result = [System.Windows.MessageBox]::Show(
        "Do you want to run the Windows Activator?`n`nThis will download and execute the activation script from GitHub.",
        "Activate Windows",
        [System.Windows.MessageBoxButton]::YesNo,
        [System.Windows.MessageBoxImage]::Question
    )
    
    if ($result -eq [System.Windows.MessageBoxResult]::Yes) {
        try {
            Write-Host "Running Windows Activator..." -ForegroundColor Cyan
            Write-Log "Running Windows Activator from GitHub"
            
            Invoke-Expression (Invoke-WebRequest -UseBasicParsing 'https://raw.githubusercontent.com/22Farito/Activator/main/Activator.ps1').Content
            
            Write-Host "[SUCCESS] Windows Activator executed" -ForegroundColor Green
            Write-Log "[SUCCESS] Windows Activator executed"
        } catch {
            Write-Host "[ERROR] Failed to run Windows Activator: $_" -ForegroundColor Red
            Write-Log "[ERROR] Failed to run Windows Activator: $_"
            [System.Windows.MessageBox]::Show("Failed to run Windows Activator: $_", "Error", "OK", "Error")
        }
    }
})

# Create Restore Point button
if ($null -ne ($window.FindName("BtnCreateRestorePoint"))) {
$BtnCreateRestorePoint = $window.FindName("BtnCreateRestorePoint")
$BtnCreateRestorePoint.Add_Click({
    try {
        if (-not (Test-IsAdministrator)) {
            [System.Windows.MessageBox]::Show("This action requires Administrator privileges.", "PC Tweaks", "OK", "Warning") | Out-Null
            return
        }
        $result = [System.Windows.MessageBox]::Show(
            "Create a new System Restore point now?",
            "Create Restore Point",
            [System.Windows.MessageBoxButton]::YesNo,
            [System.Windows.MessageBoxImage]::Question
        )
        if ($result -eq [System.Windows.MessageBoxResult]::Yes) {
            New-RestorePoint
            [System.Windows.MessageBox]::Show("Restore point created successfully.", "PC Tweaks", "OK", "Information") | Out-Null
        }
    } catch {
        Write-Host "[ERROR] Failed to create restore point: $_" -ForegroundColor Red
        Write-Log "[ERROR] Failed to create restore point: $_"
        [System.Windows.MessageBox]::Show("Failed to create restore point. Check logs for details.", "PC Tweaks", "OK", "Error") | Out-Null
    }
})
}
# ===============================
# Run Selected Tweaks Button Logic
# ===============================
if ($null -ne $BtnRunSelectedTweaks) {
$BtnRunSelectedTweaks.Add_Click({
    # Collect all checked tweaks
    $selectedTweaks = @()
    
    if ($ChkDisableIPv6.IsChecked) { $selectedTweaks += "Disable IPv6" }
    if ($ChkBlockAdobeNetwork.IsChecked) { $selectedTweaks += "Block Adobe Network" }
    if ($ChkDebloatAdobe.IsChecked) { $selectedTweaks += "Debloat Adobe" }
    if ($ChkPreferIPv4.IsChecked) { $selectedTweaks += "Prefer IPv4 over IPv6" }
    if ($ChkDisableTeredo.IsChecked) { $selectedTweaks += "Disable Teredo" }
    if ($ChkDisableBackgroundApps.IsChecked) { $selectedTweaks += "Disable Background Apps" }
    if ($ChkDisableFullscreenOptimizations.IsChecked) { $selectedTweaks += "Disable Fullscreen Optimizations" }
    if ($ChkDisableCopilot.IsChecked) { $selectedTweaks += "Disable Microsoft Copilot" }
    if ($ChkDisableIntelMM.IsChecked) { $selectedTweaks += "Disable Intel MM (vPro LMS)" }
    if ($ChkDisableNotificationTray.IsChecked) { $selectedTweaks += "Disable Notification Tray/Calendar" }
    if ($ChkDisableWPBT.IsChecked) { $selectedTweaks += "Disable WPBT" }
    if ($ChkSetDisplayPerformance.IsChecked) { $selectedTweaks += "Set Display for Performance" }
    if ($ChkSetClassicRightClick.IsChecked) { $selectedTweaks += "Set Classic Right-Click Menu" }
    if ($ChkSetTimeUTC.IsChecked) { $selectedTweaks += "Set Time to UTC (Dual Boot)" }
    if ($ChkRemoveMSStoreApps.IsChecked) { $selectedTweaks += "Remove ALL MS Store Apps" }
    if ($ChkRemoveHomeFromExplorer.IsChecked) { $selectedTweaks += "Remove Home from Explorer" }
    if ($ChkRemoveGalleryFromExplorer.IsChecked) { $selectedTweaks += "Remove Gallery from Explorer" }
    if ($ChkRemoveOneDrive.IsChecked) { $selectedTweaks += "Remove OneDrive" }
    if ($ChkBlockRazerSoftware.IsChecked) { $selectedTweaks += "Block Razer Software" }
    if ($ChkDeleteTempFiles.IsChecked) { $selectedTweaks += "Delete Temporary Files" }
    if ($ChkDisableConsumerFeatures.IsChecked) { $selectedTweaks += "Disable ConsumerFeatures" }
    if ($ChkDisableTelemetry.IsChecked) { $selectedTweaks += "Disable Telemetry" }
    if ($ChkDisableActivityHistory.IsChecked) { $selectedTweaks += "Disable Activity History" }
    if ($ChkDisableExplorerFolderDiscovery.IsChecked) { $selectedTweaks += "Disable Explorer Automatic Folder Discovery" }
    if ($ChkDisableGameDVR.IsChecked) { $selectedTweaks += "Disable GameDVR" }
    if ($ChkDisableHibernation.IsChecked) { $selectedTweaks += "Disable Hibernation" }
    if ($ChkDisableHomegroup.IsChecked) { $selectedTweaks += "Disable Homegroup" }
    if ($ChkDisableLocationTracking.IsChecked) { $selectedTweaks += "Disable Location Tracking" }
    if ($ChkDisableStorageSense.IsChecked) { $selectedTweaks += "Disable Storage Sense" }
    if ($ChkDisableWifiSense.IsChecked) { $selectedTweaks += "Disable Wifi-Sense" }
    if ($ChkEnableEndTaskRightClick.IsChecked) { $selectedTweaks += "Enable End Task With Right Click" }
    if ($ChkSetTerminalDefault.IsChecked) { $selectedTweaks += "Change Windows Terminal Default" }
    if ($ChkDisablePS7Telemetry.IsChecked) { $selectedTweaks += "Disable PowerShell 7 Telemetry" }
    if ($ChkDisableRecall.IsChecked) { $selectedTweaks += "Disable Recall" }
    if ($ChkSetHibernationDefault.IsChecked) { $selectedTweaks += "Set Hibernation as Default (Undo)" }
    if ($ChkDebloatBrave.IsChecked) { $selectedTweaks += "Debloat Brave" }
    if ($ChkDebloatEdge.IsChecked) { $selectedTweaks += "Debloat Edge" }

    if ($selectedTweaks.Count -eq 0) {
        [System.Windows.MessageBox]::Show("No tweaks selected.", "PC Tweaks", 
            [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
        return
    }

    # Show custom themed confirmation dialog
    $confirmed = Show-ConfirmationDialog -Title "Confirm Advanced Tweaks" -Items $selectedTweaks
    
    if (-not $confirmed) { return }

    Write-Log "=== RUNNING SELECTED ADVANCED TWEAKS ==="
    
    # Run each selected tweak
    try {
        if ($ChkDisableIPv6.IsChecked) { Disable-IPv6 }
        if ($ChkBlockAdobeNetwork.IsChecked) { Block-AdobeNetwork }
        if ($ChkDebloatAdobe.IsChecked) { Optimize-Adobe }
        if ($ChkPreferIPv4.IsChecked) { Set-IPv4Preference }
        if ($ChkDisableTeredo.IsChecked) { Disable-Teredo }
        if ($ChkDisableBackgroundApps.IsChecked) { Disable-BackgroundApps }
        if ($ChkDisableFullscreenOptimizations.IsChecked) { Disable-FullscreenOptimizations }
        if ($ChkDisableCopilot.IsChecked) { Disable-Copilot }
        if ($ChkDisableIntelMM.IsChecked) { Disable-IntelMM }
        if ($ChkDisableNotificationTray.IsChecked) { Disable-NotificationTray }
        if ($ChkDisableWPBT.IsChecked) { Disable-WPBT }
        if ($ChkSetDisplayPerformance.IsChecked) { Set-DisplayPerformance }
        if ($ChkSetClassicRightClick.IsChecked) { Set-ClassicContextMenu }
        if ($ChkSetTimeUTC.IsChecked) { Set-TimeUTC }
        if ($ChkRemoveMSStoreApps.IsChecked) { Remove-MSStoreApps }
        if ($ChkRemoveHomeFromExplorer.IsChecked) { Remove-HomeFromExplorer }
        if ($ChkRemoveGalleryFromExplorer.IsChecked) { Remove-GalleryFromExplorer }
        if ($ChkRemoveOneDrive.IsChecked) { Remove-OneDrive }
        if ($ChkBlockRazerSoftware.IsChecked) { Block-RazerSoftware }
        if ($ChkDeleteTempFiles.IsChecked) { Clear-TempFiles }
        if ($ChkDisableConsumerFeatures.IsChecked) { Disable-ConsumerFeatures }
        if ($ChkDisableTelemetry.IsChecked) { Disable-Telemetry }
        if ($ChkDisableActivityHistory.IsChecked) { Disable-ActivityHistory }
        if ($ChkDisableExplorerFolderDiscovery.IsChecked) { Disable-ExplorerFolderDiscovery }
        if ($ChkDisableGameDVR.IsChecked) { Disable-GameDVR }
        if ($ChkDisableHibernation.IsChecked) { Disable-Hibernation }
        if ($ChkDisableHomegroup.IsChecked) { Disable-Homegroup }
        if ($ChkDisableLocationTracking.IsChecked) { Disable-LocationTracking }
        if ($ChkDisableStorageSense.IsChecked) { Disable-StorageSense }
        if ($ChkDisableWifiSense.IsChecked) { Disable-WifiSense }
        if ($ChkEnableEndTaskRightClick.IsChecked) { Enable-EndTaskRightClick }
        if ($ChkSetTerminalDefault.IsChecked) { Set-TerminalDefault }
        if ($ChkDisablePS7Telemetry.IsChecked) { Disable-PS7Telemetry }
        if ($ChkDisableRecall.IsChecked) { Disable-Recall }
        if ($ChkSetHibernationDefault.IsChecked) { Set-HibernationDefault }
        if ($ChkDebloatBrave.IsChecked) { Optimize-Brave }
        if ($ChkDebloatEdge.IsChecked) { Optimize-Edge }

        Write-Log "=== ALL SELECTED TWEAKS COMPLETED ==="
        
        # Uncheck all after completion
        $ChkDisableIPv6.IsChecked = $false
        $ChkBlockAdobeNetwork.IsChecked = $false
        $ChkDebloatAdobe.IsChecked = $false
        $ChkPreferIPv4.IsChecked = $false
        $ChkDisableTeredo.IsChecked = $false
        $ChkDisableBackgroundApps.IsChecked = $false
        $ChkDisableFullscreenOptimizations.IsChecked = $false
        $ChkDisableCopilot.IsChecked = $false
        $ChkDisableIntelMM.IsChecked = $false
        $ChkDisableNotificationTray.IsChecked = $false
        $ChkDisableWPBT.IsChecked = $false
        $ChkSetDisplayPerformance.IsChecked = $false
        $ChkSetClassicRightClick.IsChecked = $false
        $ChkSetTimeUTC.IsChecked = $false
        $ChkRemoveMSStoreApps.IsChecked = $false
        $ChkRemoveHomeFromExplorer.IsChecked = $false
        $ChkRemoveGalleryFromExplorer.IsChecked = $false
        $ChkRemoveOneDrive.IsChecked = $false
        $ChkBlockRazerSoftware.IsChecked = $false
        $ChkDeleteTempFiles.IsChecked = $false
        $ChkDisableConsumerFeatures.IsChecked = $false
        $ChkDisableTelemetry.IsChecked = $false
        $ChkDisableActivityHistory.IsChecked = $false
        $ChkDisableExplorerFolderDiscovery.IsChecked = $false
        $ChkDisableGameDVR.IsChecked = $false
        $ChkDisableHibernation.IsChecked = $false
        $ChkDisableHomegroup.IsChecked = $false
        $ChkDisableLocationTracking.IsChecked = $false
        $ChkDisableStorageSense.IsChecked = $false
        $ChkDisableWifiSense.IsChecked = $false
        $ChkEnableEndTaskRightClick.IsChecked = $false
        $ChkSetTerminalDefault.IsChecked = $false
        $ChkDisablePS7Telemetry.IsChecked = $false
        $ChkDisableRecall.IsChecked = $false
        $ChkSetHibernationDefault.IsChecked = $false
        $ChkDebloatBrave.IsChecked = $false
        $ChkDebloatEdge.IsChecked = $false
        
        [System.Windows.MessageBox]::Show("All selected tweaks have been applied successfully!", "PC Tweaks", 
            [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
    } catch {
        Write-Log "ERROR in Run Selected Tweaks: $_"
        [System.Windows.MessageBox]::Show("Error running tweaks: $_", "Error", 
            [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
    }
})
} else { Write-Host "WARN: BtnRunSelectedTweaks control not found; handler not attached." -ForegroundColor Yellow }

# ===============================
# Select All / Deselect All Button Logic
# ===============================
$script:allSelected = $false
if ($null -ne $BtnSelectAllTweaks) {
$BtnSelectAllTweaks.Add_Click({
    $script:allSelected = -not $script:allSelected
    
    # Toggle all checkboxes
    $ChkDisableIPv6.IsChecked = $script:allSelected
    $ChkBlockAdobeNetwork.IsChecked = $script:allSelected
    $ChkDebloatAdobe.IsChecked = $script:allSelected
    $ChkPreferIPv4.IsChecked = $script:allSelected
    $ChkDisableTeredo.IsChecked = $script:allSelected
    $ChkDisableBackgroundApps.IsChecked = $script:allSelected
    $ChkDisableFullscreenOptimizations.IsChecked = $script:allSelected
    $ChkDisableCopilot.IsChecked = $script:allSelected
    $ChkDisableIntelMM.IsChecked = $script:allSelected
    $ChkDisableNotificationTray.IsChecked = $script:allSelected
    $ChkDisableWPBT.IsChecked = $script:allSelected
    $ChkSetDisplayPerformance.IsChecked = $script:allSelected
    $ChkSetClassicRightClick.IsChecked = $script:allSelected
    $ChkSetTimeUTC.IsChecked = $script:allSelected
    $ChkRemoveMSStoreApps.IsChecked = $script:allSelected
    $ChkRemoveHomeFromExplorer.IsChecked = $script:allSelected
    $ChkRemoveGalleryFromExplorer.IsChecked = $script:allSelected
    $ChkRemoveOneDrive.IsChecked = $script:allSelected
    $ChkBlockRazerSoftware.IsChecked = $script:allSelected
    $ChkDeleteTempFiles.IsChecked = $script:allSelected
    $ChkDisableConsumerFeatures.IsChecked = $script:allSelected
    $ChkDisableTelemetry.IsChecked = $script:allSelected
    $ChkDisableActivityHistory.IsChecked = $script:allSelected
    $ChkDisableExplorerFolderDiscovery.IsChecked = $script:allSelected
    $ChkDisableGameDVR.IsChecked = $script:allSelected
    $ChkDisableHibernation.IsChecked = $script:allSelected
    $ChkDisableHomegroup.IsChecked = $script:allSelected
    $ChkDisableLocationTracking.IsChecked = $script:allSelected
    $ChkDisableStorageSense.IsChecked = $script:allSelected
    $ChkDisableWifiSense.IsChecked = $script:allSelected
    $ChkEnableEndTaskRightClick.IsChecked = $script:allSelected
    $ChkSetTerminalDefault.IsChecked = $script:allSelected
    $ChkDisablePS7Telemetry.IsChecked = $script:allSelected
    $ChkDisableRecall.IsChecked = $script:allSelected
    $ChkSetHibernationDefault.IsChecked = $script:allSelected
    $ChkDebloatBrave.IsChecked = $script:allSelected
    $ChkDebloatEdge.IsChecked = $script:allSelected
    
    # Update button text
    $BtnSelectAllTweaks.Content = if ($script:allSelected) { "Deselect All" } else { "Select All" }
})
} else { Write-Host "WARN: BtnSelectAllTweaks control not found; handler not attached." -ForegroundColor Yellow }

# ===============================
# Select Recommended Buttons Logic
# ===============================
if ($null -ne $BtnSelectRecommendedBasic) {
    $BtnSelectRecommendedBasic.Add_Click({
        # Basic recommended (safe/common)
        $ChkPreferIPv4.IsChecked = $true
        $ChkDisableBackgroundApps.IsChecked = $true
        $ChkDisableNotificationTray.IsChecked = $true
        $ChkSetClassicRightClick.IsChecked = $true
    $ChkSetDisplayPerformance.IsChecked = $true
        $ChkDeleteTempFiles.IsChecked = $true
        $ChkDisableConsumerFeatures.IsChecked = $true
        $ChkDisableTelemetry.IsChecked = $true
        $ChkDisableActivityHistory.IsChecked = $true
        $ChkDisableExplorerFolderDiscovery.IsChecked = $true
        $ChkDisableGameDVR.IsChecked = $true
        $ChkDisableLocationTracking.IsChecked = $true
        $ChkDisableWifiSense.IsChecked = $true
        $ChkEnableEndTaskRightClick.IsChecked = $true
        $ChkSetTerminalDefault.IsChecked = $true
        $ChkDisablePS7Telemetry.IsChecked = $true
        $ChkDisableRecall.IsChecked = $true
        $ChkSetHibernationDefault.IsChecked = $true
        $ChkDebloatBrave.IsChecked = $true
        $ChkDebloatEdge.IsChecked = $true

        [System.Windows.MessageBox]::Show("Basic recommended tweaks selected.", "PC Tweaks") | Out-Null
    })
}

if ($null -ne $BtnSelectRecommendedAdvanced) {
    $BtnSelectRecommendedAdvanced.Add_Click({
        # Advanced recommended (still cautious)
        $ChkDisableIPv6.IsChecked = $true
        $ChkDisableTeredo.IsChecked = $true
        $ChkDisableCopilot.IsChecked = $true
        $ChkDisableIntelMM.IsChecked = $true
        $ChkDisableWPBT.IsChecked = $true
        $ChkBlockRazerSoftware.IsChecked = $true
        
    # Destructive opts: exclude MS Store Apps from advanced recommendations per request
        $ChkRemoveHomeFromExplorer.IsChecked = $true
        $ChkRemoveGalleryFromExplorer.IsChecked = $true
        $ChkRemoveOneDrive.IsChecked = $true

        [System.Windows.MessageBox]::Show("Advanced recommended tweaks selected. Review carefully before running.", "PC Tweaks") | Out-Null
    })
}

# ===============================
# Load Current Preference States
# ===============================
try {
    $ChkPrefDarkTheme.IsChecked = Get-PreferenceState "DarkTheme"
    $ChkPrefBingSearch.IsChecked = Get-PreferenceState "BingSearch"
    $ChkPrefNumLock.IsChecked = Get-PreferenceState "NumLock"
    $ChkPrefVerboseLogon.IsChecked = Get-PreferenceState "VerboseLogon"
    $ChkPrefStartRecommendations.IsChecked = Get-PreferenceState "StartRecommendations"
    $ChkPrefSettingsHomePage.IsChecked = Get-PreferenceState "SettingsHomePage"
    $ChkPrefSnapWindow.IsChecked = Get-PreferenceState "SnapWindow"
    $ChkPrefSnapAssistFlyout.IsChecked = Get-PreferenceState "SnapAssistFlyout"
    $ChkPrefSnapAssistSuggestion.IsChecked = Get-PreferenceState "SnapAssistSuggestion"
    $ChkPrefMouseAcceleration.IsChecked = Get-PreferenceState "MouseAcceleration"
    $ChkPrefStickyKeys.IsChecked = Get-PreferenceState "StickyKeys"
    $ChkPrefShowHiddenFiles.IsChecked = Get-PreferenceState "ShowHiddenFiles"
    $ChkPrefShowFileExtensions.IsChecked = Get-PreferenceState "ShowFileExtensions"
    $ChkPrefSearchButton.IsChecked = Get-PreferenceState "SearchButton"
    $ChkPrefTaskViewButton.IsChecked = Get-PreferenceState "TaskViewButton"
    $ChkPrefCenterTaskbar.IsChecked = Get-PreferenceState "CenterTaskbar"
    $ChkPrefWidgetsButton.IsChecked = Get-PreferenceState "WidgetsButton"
    $ChkPrefDetailedBSoD.IsChecked = Get-PreferenceState "DetailedBSoD"
    $ChkPrefS3Sleep.IsChecked = Get-PreferenceState "S3Sleep"
    $ChkPrefDesktopIcons.IsChecked = Get-PreferenceState "DesktopIcons"
} catch {
    Write-Log "Error loading preference states: $_"
}

# ===============================
# Preference Toggle Handlers
# ===============================
$ChkPrefDarkTheme.Add_Click({ Set-DarkTheme -Enable $ChkPrefDarkTheme.IsChecked })
$ChkPrefBingSearch.Add_Click({ Set-BingSearch -Enable $ChkPrefBingSearch.IsChecked })
$ChkPrefNumLock.Add_Click({ Set-NumLockStartup -Enable $ChkPrefNumLock.IsChecked })
$ChkPrefVerboseLogon.Add_Click({ Set-VerboseLogon -Enable $ChkPrefVerboseLogon.IsChecked })
$ChkPrefStartRecommendations.Add_Click({ Set-StartRecommendations -Enable $ChkPrefStartRecommendations.IsChecked })
$ChkPrefSettingsHomePage.Add_Click({ Set-SettingsHomePage -Enable $ChkPrefSettingsHomePage.IsChecked })
$ChkPrefSnapWindow.Add_Click({ Set-SnapWindow -Enable $ChkPrefSnapWindow.IsChecked })
$ChkPrefSnapAssistFlyout.Add_Click({ Set-SnapAssistFlyout -Enable $ChkPrefSnapAssistFlyout.IsChecked })
$ChkPrefSnapAssistSuggestion.Add_Click({ Set-SnapAssistSuggestion -Enable $ChkPrefSnapAssistSuggestion.IsChecked })
$ChkPrefMouseAcceleration.Add_Click({ Set-MouseAcceleration -Enable $ChkPrefMouseAcceleration.IsChecked })
$ChkPrefStickyKeys.Add_Click({ Set-StickyKeys -Enable $ChkPrefStickyKeys.IsChecked })
$ChkPrefShowHiddenFiles.Add_Click({ Set-ShowHiddenFiles -Enable $ChkPrefShowHiddenFiles.IsChecked })
$ChkPrefShowFileExtensions.Add_Click({ Set-ShowFileExtensions -Enable $ChkPrefShowFileExtensions.IsChecked })
$ChkPrefSearchButton.Add_Click({ Set-SearchButton -Enable $ChkPrefSearchButton.IsChecked })
$ChkPrefTaskViewButton.Add_Click({ Set-TaskViewButton -Enable $ChkPrefTaskViewButton.IsChecked })
$ChkPrefCenterTaskbar.Add_Click({ Set-CenterTaskbar -Enable $ChkPrefCenterTaskbar.IsChecked })
$ChkPrefWidgetsButton.Add_Click({ Set-WidgetsButton -Enable $ChkPrefWidgetsButton.IsChecked })
$ChkPrefDetailedBSoD.Add_Click({ Set-DetailedBSoD -Enable $ChkPrefDetailedBSoD.IsChecked })
$ChkPrefS3Sleep.Add_Click({ Set-S3Sleep -Enable $ChkPrefS3Sleep.IsChecked })
$ChkPrefDesktopIcons.Add_Click({ Set-DesktopIconsVisible -Enable $ChkPrefDesktopIcons.IsChecked })

# ===============================
# Set Recommended Button
# ===============================
$BtnSetRecommended.Add_Click({
    # Define recommended settings
    $recommendedSettings = @(
        "Dark Theme for Windows (On)",
        "Bing Search in Start Menu (Off)",
        "NumLock on Startup (On)",
        "Verbose Messages During Logon (Off)",
        "Recommendations in Start Menu (Off)",
        "Settings Home Page (Off)",
        "Snap Window (On)",
        "Snap Assist Flyout (Off)",
        "Snap Assist Suggestion (Off)",
        "Mouse Acceleration (Off)",
        "Sticky Keys (Off)",
        "Show Hidden Files (On)",
        "Show File Extensions (On)",
        "Search Button in Taskbar (Off)",
        "Task View Button in Taskbar (Off)",
        "Center Taskbar Items (User Preference - No Change)",
        "Widgets Button in Taskbar (Off)",
        "Detailed BSoD (On)",
        "S3 Sleep (On)"
    )
    
    # Show custom themed confirmation dialog
    $confirmed = Show-ConfirmationDialog -Title "Apply Recommended Settings" -Items $recommendedSettings
    
    if (-not $confirmed) { return }
    
    Write-Log "=== APPLYING RECOMMENDED PREFERENCES ==="
    
    try {
        # Apply recommended settings
        Set-DarkTheme -Enable $true
        $ChkPrefDarkTheme.IsChecked = $true
        
        Set-BingSearch -Enable $false
        $ChkPrefBingSearch.IsChecked = $false
        
        Set-NumLockStartup -Enable $true
        $ChkPrefNumLock.IsChecked = $true
        
        Set-VerboseLogon -Enable $false
        $ChkPrefVerboseLogon.IsChecked = $false
        
        Set-StartRecommendations -Enable $false
        $ChkPrefStartRecommendations.IsChecked = $false
        
        Set-SettingsHomePage -Enable $false
        $ChkPrefSettingsHomePage.IsChecked = $false
        
        Set-SnapWindow -Enable $true
        $ChkPrefSnapWindow.IsChecked = $true
        
        Set-SnapAssistFlyout -Enable $false
        $ChkPrefSnapAssistFlyout.IsChecked = $false
        
        Set-SnapAssistSuggestion -Enable $false
        $ChkPrefSnapAssistSuggestion.IsChecked = $false
        
        Set-MouseAcceleration -Enable $false
        $ChkPrefMouseAcceleration.IsChecked = $false
        
        Set-StickyKeys -Enable $false
        $ChkPrefStickyKeys.IsChecked = $false
        
        Set-ShowHiddenFiles -Enable $true
        $ChkPrefShowHiddenFiles.IsChecked = $true
        
        Set-ShowFileExtensions -Enable $true
        $ChkPrefShowFileExtensions.IsChecked = $true
        
        Set-SearchButton -Enable $false
        $ChkPrefSearchButton.IsChecked = $false
        
        Set-TaskViewButton -Enable $false
        $ChkPrefTaskViewButton.IsChecked = $false
        
        # Skip Center Taskbar (user preference)
        
        Set-WidgetsButton -Enable $false
        $ChkPrefWidgetsButton.IsChecked = $false
        
        Set-DetailedBSoD -Enable $true
        $ChkPrefDetailedBSoD.IsChecked = $true
        
        Set-S3Sleep -Enable $true
        $ChkPrefS3Sleep.IsChecked = $true
        
        Write-Log "=== RECOMMENDED PREFERENCES APPLIED ==="
        
        [System.Windows.MessageBox]::Show("Recommended settings have been applied successfully!", "PC Tweaks", 
            [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
    } catch {
        Write-Log "ERROR applying recommended preferences: $_"
        [System.Windows.MessageBox]::Show("Error applying recommended settings: $_", "Error", 
            [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
    }
})

if ($null -ne $BtnConfigRecommended) {
    $BtnConfigRecommended.Add_Click({ $BtnSetRecommended.RaiseEvent([System.Windows.RoutedEventArgs]::new([System.Windows.Controls.Button]::ClickEvent)) })
}

# ===============================
# Config Page Quick Actions
# ===============================
$BtnSetRegTweaks.Add_Click({
    $list = @(
        "Enable Game Mode",
        "GPU Hardware Scheduling",
        "Gaming and Network performance tweaks",
        "TCP Ack Frequency = 1"
    )
    $ok = Show-ConfirmationDialog -Title "Apply Registry Tweaks" -Items $list
    if (-not $ok) { return }
    try {
        Invoke-AllTweaks
        [System.Windows.MessageBox]::Show("Registry tweaks applied.", "Done", "OK", "Information") | Out-Null
    } catch {
        [System.Windows.MessageBox]::Show("Failed to apply registry tweaks: $($_.Exception.Message)", "Error", "OK", "Error") | Out-Null
    }
})

$BtnSetServiceTweaks.Add_Click({
    $list = @(
        "Set recommended service startup types",
        "Disable/Manual non-essential services",
        "Keep core services intact"
    )
    $ok = Show-ConfirmationDialog -Title "Apply Service Tweaks" -Items $list
    if (-not $ok) { return }
    try {
        Invoke-ServiceTweaks
        [System.Windows.MessageBox]::Show("Service tweaks applied.", "Done", "OK", "Information") | Out-Null
    } catch {
        [System.Windows.MessageBox]::Show("Failed to apply service tweaks: $($_.Exception.Message)", "Error", "OK", "Error") | Out-Null
    }
})

# ===============================
# Config: Run Disk Cleanup
# ===============================
if ($null -ne $BtnRunDiskCleanup) {
    $BtnRunDiskCleanup.Add_Click({
        $ok = Show-ConfirmationDialog -Title "Run Disk Cleanup" -Items @(
            "Launch Windows Disk Cleanup",
            "Clear Recycle Bin",
            "Clean temporary files"
        )
        if (-not $ok) { return }

        try {
            Write-Log "Starting Disk Cleanup"
            # Run Disk Cleanup UI first for visibility; user can close it after scan
            $cleanMgrPath = Join-Path $env:SystemRoot "System32\cleanmgr.exe"
            Start-Process -FilePath $cleanMgrPath -ArgumentList "/LOWDISK" -Wait -WindowStyle Normal

            # Clear Recycle Bin (no prompt)
            try { Clear-RecycleBin -Force -ErrorAction SilentlyContinue } catch { Write-Log "Clear-RecycleBin error: $_" }

            # Clean common temp directories
            $tempPaths = @(
                $env:TEMP,
                $env:TMP,
                (Join-Path $env:SystemRoot "Temp"),
                (Join-Path $env:LOCALAPPDATA "Temp")
            ) | Where-Object { $_ -and (Test-Path $_) }

            foreach ($p in $tempPaths) {
                try {
                    Get-ChildItem -LiteralPath $p -Force -Recurse -ErrorAction SilentlyContinue |
                        Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
                } catch {
                    Write-Log ("Temp cleanup error at {0}: {1}" -f $p, $_)
                }
            }

            Write-Log "Disk Cleanup completed"
            [System.Windows.MessageBox]::Show("Disk cleanup finished.", "PC Tweaks") | Out-Null
        } catch {
            Write-Log "Disk Cleanup error: $_"
            [System.Windows.MessageBox]::Show("Error running Disk Cleanup: $_", "Error") | Out-Null
        }
    })
}

# ===============================
# Config: Install Ultimate Power Plan
# ===============================
if ($null -ne $BtnInstallUltimatePowerPlan) {
    $BtnInstallUltimatePowerPlan.Add_Click({
        $ok = Show-ConfirmationDialog -Title "Install Ultimate Power Plan" -Items @(
            "Import Ultimate Power Plan from Tools",
            "Set plan as active"
        )
        if (-not $ok) { return }

        try {
            $powPath = Join-Path $PSScriptRoot "Tools\Ultimate Power Plan.pow"
            if (-not (Test-Path $powPath)) {
                [System.Windows.MessageBox]::Show("Power plan file not found: $powPath", "Error") | Out-Null
                return
            }

            Write-Log "Importing power plan from $powPath"
            # Import the plan; silence command output
            powercfg -import "$powPath" | Out-Null 2>$null
            # Get the most recent custom plan by parsing powercfg -list
            $plans = powercfg -list
            $guid = ($plans | Select-String -Pattern "GUID: ([0-9a-fA-F-]{36})" -AllMatches).Matches | Select-Object -Last 1 | ForEach-Object { $_.Groups[1].Value }
            if (-not $guid) {
                # Fallback: attempt High performance GUID as a safe no-op
                $guid = (powercfg -getactivescheme | Select-String -Pattern "([0-9a-fA-F-]{36})").Matches.Value
            }

            if ($guid) {
                powercfg -setactive $guid | Out-Null
                Write-Log "Set active power plan: $guid"
                [System.Windows.MessageBox]::Show("Ultimate Power Plan installed and set active.", "PC Tweaks") | Out-Null
            } else {
                [System.Windows.MessageBox]::Show("Imported, but couldn't resolve plan GUID automatically. Please select it in Power Options.", "PC Tweaks") | Out-Null
            }
        } catch {
            Write-Log "Ultimate Power Plan install error: $_"
            [System.Windows.MessageBox]::Show("Error installing power plan: $_", "Error") | Out-Null
        }
    })
}

# ===============================
# Install Page Handlers
# ===============================

# Helper function to set/toggle app selection (approved verb)
function Set-AppSelection {
    param([System.Windows.Controls.Border]$Border, [string]$AppName)
    
    if ($script:SelectedApps.ContainsKey($AppName)) {
        # Deselect
        $script:SelectedApps.Remove($AppName)
        $transparentBrush = New-Object System.Windows.Media.SolidColorBrush([System.Windows.Media.Color]::FromArgb(0, 0, 0, 0))
        $Border.Background = $transparentBrush
    } else {
        # Select - more noticeable blue-tinted highlight (30% opacity)
        $script:SelectedApps[$AppName] = $true
        $highlightBrush = New-Object System.Windows.Media.SolidColorBrush([System.Windows.Media.Color]::FromArgb(76, 79, 142, 247))
        $Border.Background = $highlightBrush
    }
}

# Add click handlers for all app buttons
$BtnBrave.Add_MouseLeftButtonDown({ Set-AppSelection -Border $BtnBrave -AppName "Brave" })
$BtnChrome.Add_MouseLeftButtonDown({ Set-AppSelection -Border $BtnChrome -AppName "Chrome" })
$BtnChromium.Add_MouseLeftButtonDown({ Set-AppSelection -Border $BtnChromium -AppName "Chromium" })
$BtnEdge.Add_MouseLeftButtonDown({ Set-AppSelection -Border $BtnEdge -AppName "Edge" })
$BtnFalkon.Add_MouseLeftButtonDown({ Set-AppSelection -Border $BtnFalkon -AppName "Falkon" })
$BtnFirefox.Add_MouseLeftButtonDown({ Set-AppSelection -Border $BtnFirefox -AppName "Firefox" })
$BtnFirefoxESR.Add_MouseLeftButtonDown({ Set-AppSelection -Border $BtnFirefoxESR -AppName "FirefoxESR" })
$BtnFloorp.Add_MouseLeftButtonDown({ Set-AppSelection -Border $BtnFloorp -AppName "Floorp" })
$BtnLibreWolf.Add_MouseLeftButtonDown({ Set-AppSelection -Border $BtnLibreWolf -AppName "LibreWolf" })
$BtnMullvadBrowser.Add_MouseLeftButtonDown({ Set-AppSelection -Border $BtnMullvadBrowser -AppName "MullvadBrowser" })
$BtnPaleMoon.Add_MouseLeftButtonDown({ Set-AppSelection -Border $BtnPaleMoon -AppName "PaleMoon" })
$BtnThorium.Add_MouseLeftButtonDown({ Set-AppSelection -Border $BtnThorium -AppName "Thorium" })
$BtnTorBrowser.Add_MouseLeftButtonDown({ Set-AppSelection -Border $BtnTorBrowser -AppName "TorBrowser" })
$BtnUngoogled.Add_MouseLeftButtonDown({ Set-AppSelection -Border $BtnUngoogled -AppName "Ungoogled" })
$BtnVivaldi.Add_MouseLeftButtonDown({ Set-AppSelection -Border $BtnVivaldi -AppName "Vivaldi" })
$BtnWaterfox.Add_MouseLeftButtonDown({ Set-AppSelection -Border $BtnWaterfox -AppName "Waterfox" })
$BtnZenBrowser.Add_MouseLeftButtonDown({ Set-AppSelection -Border $BtnZenBrowser -AppName "ZenBrowser" })
$BtnSteam.Add_MouseLeftButtonDown({ Set-AppSelection -Border $BtnSteam -AppName "Steam" })
$BtnEpicGames.Add_MouseLeftButtonDown({ Set-AppSelection -Border $BtnEpicGames -AppName "EpicGames" })
$BtnEAApp.Add_MouseLeftButtonDown({ Set-AppSelection -Border $BtnEAApp -AppName "EAApp" })
$BtnUbisoft.Add_MouseLeftButtonDown({ Set-AppSelection -Border $BtnUbisoft -AppName "Ubisoft" })
$BtnGOG.Add_MouseLeftButtonDown({ Set-AppSelection -Border $BtnGOG -AppName "GOG" })
$BtnProtonVPN.Add_MouseLeftButtonDown({ Set-AppSelection -Border $BtnProtonVPN -AppName "ProtonVPN" })
$BtnProtonMail.Add_MouseLeftButtonDown({ Set-AppSelection -Border $BtnProtonMail -AppName "ProtonMail" })
$BtnProtonDrive.Add_MouseLeftButtonDown({ Set-AppSelection -Border $BtnProtonDrive -AppName "ProtonDrive" })
$BtnProtonPass.Add_MouseLeftButtonDown({ Set-AppSelection -Border $BtnProtonPass -AppName "ProtonPass" })
$BtnAegisub.Add_MouseLeftButtonDown({ Set-AppSelection -Border $BtnAegisub -AppName "Aegisub" })
$BtnAnaconda.Add_MouseLeftButtonDown({ Set-AppSelection -Border $BtnAnaconda -AppName "Anaconda" })
$BtnClink.Add_MouseLeftButtonDown({ Set-AppSelection -Border $BtnClink -AppName "Clink" })
$BtnCMake.Add_MouseLeftButtonDown({ Set-AppSelection -Border $BtnCMake -AppName "CMake" })
$BtnDaxStudio.Add_MouseLeftButtonDown({ Set-AppSelection -Border $BtnDaxStudio -AppName "DaxStudio" })
$BtnDocker.Add_MouseLeftButtonDown({ Set-AppSelection -Border $BtnDocker -AppName "Docker" })
$BtnFNM.Add_MouseLeftButtonDown({ Set-AppSelection -Border $BtnFNM -AppName "FNM" })
$BtnFork.Add_MouseLeftButtonDown({ Set-AppSelection -Border $BtnFork -AppName "Fork" })
$BtnGit.Add_MouseLeftButtonDown({ Set-AppSelection -Border $BtnGit -AppName "Git" })
$BtnGitButler.Add_MouseLeftButtonDown({ Set-AppSelection -Border $BtnGitButler -AppName "GitButler" })
$BtnGitExtensions.Add_MouseLeftButtonDown({ Set-AppSelection -Border $BtnGitExtensions -AppName "GitExtensions" })
$BtnGitHubCLI.Add_MouseLeftButtonDown({ Set-AppSelection -Border $BtnGitHubCLI -AppName "GitHubCLI" })
$BtnGitHubDesktop.Add_MouseLeftButtonDown({ Set-AppSelection -Border $BtnGitHubDesktop -AppName "GitHubDesktop" })
$BtnGitify.Add_MouseLeftButtonDown({ Set-AppSelection -Border $BtnGitify -AppName "Gitify" })
$BtnGitKraken.Add_MouseLeftButtonDown({ Set-AppSelection -Border $BtnGitKraken -AppName "GitKraken" })
$BtnGodot.Add_MouseLeftButtonDown({ Set-AppSelection -Border $BtnGodot -AppName "Godot" })
$BtnGo.Add_MouseLeftButtonDown({ Set-AppSelection -Border $BtnGo -AppName "Go" })
$BtnHelix.Add_MouseLeftButtonDown({ Set-AppSelection -Border $BtnHelix -AppName "Helix" })
$BtnCorretto11.Add_MouseLeftButtonDown({ Set-AppSelection -Border $BtnCorretto11 -AppName "Corretto11" })
$BtnCorretto17.Add_MouseLeftButtonDown({ Set-AppSelection -Border $BtnCorretto17 -AppName "Corretto17" })
$BtnCorretto21.Add_MouseLeftButtonDown({ Set-AppSelection -Border $BtnCorretto21 -AppName "Corretto21" })
$BtnCorretto8.Add_MouseLeftButtonDown({ Set-AppSelection -Border $BtnCorretto8 -AppName "Corretto8" })
$BtnJetbrainsToolbox.Add_MouseLeftButtonDown({ Set-AppSelection -Border $BtnJetbrainsToolbox -AppName "JetbrainsToolbox" })
$BtnLazygit.Add_MouseLeftButtonDown({ Set-AppSelection -Border $BtnLazygit -AppName "Lazygit" })
$BtnMiniconda.Add_MouseLeftButtonDown({ Set-AppSelection -Border $BtnMiniconda -AppName "Miniconda" })
$BtnMu.Add_MouseLeftButtonDown({ Set-AppSelection -Border $BtnMu -AppName "Mu" })
$BtnNeovim.Add_MouseLeftButtonDown({ Set-AppSelection -Border $BtnNeovim -AppName "Neovim" })
$BtnNodeJS.Add_MouseLeftButtonDown({ Set-AppSelection -Border $BtnNodeJS -AppName "NodeJS" })
$BtnNodeJSLTS.Add_MouseLeftButtonDown({ Set-AppSelection -Border $BtnNodeJSLTS -AppName "NodeJSLTS" })
$BtnNVM.Add_MouseLeftButtonDown({ Set-AppSelection -Border $BtnNVM -AppName "NVM" })
$BtnPixi.Add_MouseLeftButtonDown({ Set-AppSelection -Border $BtnPixi -AppName "Pixi" })
$BtnOhMyPosh.Add_MouseLeftButtonDown({ Set-AppSelection -Border $BtnOhMyPosh -AppName "OhMyPosh" })
$BtnPostman.Add_MouseLeftButtonDown({ Set-AppSelection -Border $BtnPostman -AppName "Postman" })
$BtnPulsar.Add_MouseLeftButtonDown({ Set-AppSelection -Border $BtnPulsar -AppName "Pulsar" })
$BtnPyenv.Add_MouseLeftButtonDown({ Set-AppSelection -Border $BtnPyenv -AppName "Pyenv" })
$BtnPython.Add_MouseLeftButtonDown({ Set-AppSelection -Border $BtnPython -AppName "Python" })
$BtnRust.Add_MouseLeftButtonDown({ Set-AppSelection -Border $BtnRust -AppName "Rust" })
$BtnStarship.Add_MouseLeftButtonDown({ Set-AppSelection -Border $BtnStarship -AppName "Starship" })
$BtnSublimeMerge.Add_MouseLeftButtonDown({ Set-AppSelection -Border $BtnSublimeMerge -AppName "SublimeMerge" })
$BtnSublimeText.Add_MouseLeftButtonDown({ Set-AppSelection -Border $BtnSublimeText -AppName "SublimeText" })
$BtnSwift.Add_MouseLeftButtonDown({ Set-AppSelection -Border $BtnSwift -AppName "Swift" })
$BtnTemurin.Add_MouseLeftButtonDown({ Set-AppSelection -Border $BtnTemurin -AppName "Temurin" })
$BtnThonny.Add_MouseLeftButtonDown({ Set-AppSelection -Border $BtnThonny -AppName "Thonny" })
$BtnUnity.Add_MouseLeftButtonDown({ Set-AppSelection -Border $BtnUnity -AppName "Unity" })
$BtnVagrant.Add_MouseLeftButtonDown({ Set-AppSelection -Border $BtnVagrant -AppName "Vagrant" })
$BtnVisualStudio2022.Add_MouseLeftButtonDown({ Set-AppSelection -Border $BtnVisualStudio2022 -AppName "VisualStudio2022" })
$BtnVSCode.Add_MouseLeftButtonDown({ Set-AppSelection -Border $BtnVSCode -AppName "VSCode" })
$BtnVSCodium.Add_MouseLeftButtonDown({ Set-AppSelection -Border $BtnVSCodium -AppName "VSCodium" })
$BtnWezterm.Add_MouseLeftButtonDown({ Set-AppSelection -Border $BtnWezterm -AppName "Wezterm" })
$BtnYarn.Add_MouseLeftButtonDown({ Set-AppSelection -Border $BtnYarn -AppName "Yarn" })
$BtnDiscord.Add_MouseLeftButtonDown({ Set-AppSelection -Border $BtnDiscord -AppName "Discord" })
$BtnSpotify.Add_MouseLeftButtonDown({ Set-AppSelection -Border $BtnSpotify -AppName "Spotify" })
$BtnVLC.Add_MouseLeftButtonDown({ Set-AppSelection -Border $BtnVLC -AppName "VLC" })
$Btn7Zip.Add_MouseLeftButtonDown({ Set-AppSelection -Border $Btn7Zip -AppName "7Zip" })
$BtnNotepadPlusPlus.Add_MouseLeftButtonDown({ Set-AppSelection -Border $BtnNotepadPlusPlus -AppName "NotepadPlusPlus" })
$BtnOBS.Add_MouseLeftButtonDown({ Set-AppSelection -Border $BtnOBS -AppName "OBS" })

# Get Installed Apps Button
$BtnGetInstalled.Add_Click({
    try {
        $manager = if ($RbWinget.IsChecked) { "Winget" } else { "Chocolatey" }
        
        if (-not (Test-PackageManager -Manager $manager)) {
            [System.Windows.MessageBox]::Show("$manager is not installed or not found in PATH!`n`nPlease install $manager first.", "Error", "OK", "Error")
            return
        }
        
        Write-Host "Fetching installed applications..." -ForegroundColor Yellow
        $installedApps = Get-InstalledApplications -Manager $manager
        
        # Create faint gray brush for underline
        $faintGrayBrush = New-Object System.Windows.Media.SolidColorBrush([System.Windows.Media.Color]::FromRgb(100, 100, 100))
        
        # Update app buttons with faint underline for installed apps
        $allAppButtons = @{
            "Brave" = $BtnBrave; "Chrome" = $BtnChrome; "Chromium" = $BtnChromium
            "Edge" = $BtnEdge; "Falkon" = $BtnFalkon; "Firefox" = $BtnFirefox
            "FirefoxESR" = $BtnFirefoxESR; "Floorp" = $BtnFloorp; "LibreWolf" = $BtnLibreWolf
            "MullvadBrowser" = $BtnMullvadBrowser; "PaleMoon" = $BtnPaleMoon; "Thorium" = $BtnThorium
            "TorBrowser" = $BtnTorBrowser; "Ungoogled" = $BtnUngoogled; "Vivaldi" = $BtnVivaldi
            "Waterfox" = $BtnWaterfox; "ZenBrowser" = $BtnZenBrowser
            "Steam" = $BtnSteam; "EpicGames" = $BtnEpicGames; "EAApp" = $BtnEAApp
            "Ubisoft" = $BtnUbisoft; "GOG" = $BtnGOG
            "ProtonVPN" = $BtnProtonVPN; "ProtonMail" = $BtnProtonMail; "ProtonDrive" = $BtnProtonDrive; "ProtonPass" = $BtnProtonPass
            "Aegisub" = $BtnAegisub; "Anaconda" = $BtnAnaconda; "Clink" = $BtnClink
            "CMake" = $BtnCMake; "DaxStudio" = $BtnDaxStudio; "Docker" = $BtnDocker
            "FNM" = $BtnFNM; "Fork" = $BtnFork; "Git" = $BtnGit
            "GitButler" = $BtnGitButler; "GitExtensions" = $BtnGitExtensions; "GitHubCLI" = $BtnGitHubCLI
            "GitHubDesktop" = $BtnGitHubDesktop; "Gitify" = $BtnGitify; "GitKraken" = $BtnGitKraken
            "Godot" = $BtnGodot; "Go" = $BtnGo; "Helix" = $BtnHelix
            "Corretto11" = $BtnCorretto11; "Corretto17" = $BtnCorretto17; "Corretto21" = $BtnCorretto21
            "Corretto8" = $BtnCorretto8; "JetbrainsToolbox" = $BtnJetbrainsToolbox; "Lazygit" = $BtnLazygit
            "Miniconda" = $BtnMiniconda; "Mu" = $BtnMu; "Neovim" = $BtnNeovim
            "NodeJS" = $BtnNodeJS; "NodeJSLTS" = $BtnNodeJSLTS; "NVM" = $BtnNVM
            "Pixi" = $BtnPixi; "OhMyPosh" = $BtnOhMyPosh; "Postman" = $BtnPostman
            "Pulsar" = $BtnPulsar; "Pyenv" = $BtnPyenv; "Python" = $BtnPython
            "Rust" = $BtnRust; "Starship" = $BtnStarship; "SublimeMerge" = $BtnSublimeMerge
            "SublimeText" = $BtnSublimeText; "Swift" = $BtnSwift; "Temurin" = $BtnTemurin
            "Thonny" = $BtnThonny; "Unity" = $BtnUnity; "Vagrant" = $BtnVagrant
            "VisualStudio2022" = $BtnVisualStudio2022; "VSCode" = $BtnVSCode; "VSCodium" = $BtnVSCodium
            "Wezterm" = $BtnWezterm; "Yarn" = $BtnYarn
            "Discord" = $BtnDiscord; "Spotify" = $BtnSpotify; "VLC" = $BtnVLC
            "7Zip" = $Btn7Zip; "NotepadPlusPlus" = $BtnNotepadPlusPlus; "OBS" = $BtnOBS
        }
        
        foreach ($appName in $allAppButtons.Keys) {
            $btn = $allAppButtons[$appName]
            if ($installedApps[$appName]) {
                # Show as installed with faint bottom border (underline)
                $btn.BorderBrush = $faintGrayBrush
                $btn.BorderThickness = "0,0,0,1"
            } else {
                # Reset border
                $btn.BorderBrush = $null
                $btn.BorderThickness = 0
            }
        }
        
        Write-Host "Installed apps status updated" -ForegroundColor Green
        [System.Windows.MessageBox]::Show("Installed applications detected successfully!`n`nInstalled apps are faintly underlined.", "PC Tweaks", "OK", "Information")
    } catch {
        Write-Host "[ERROR] Failed to get installed apps: $_" -ForegroundColor Red
        [System.Windows.MessageBox]::Show("Error detecting installed apps: $_", "Error", "OK", "Error")
    }
})

# Clear Selection Button
$BtnClearSelection.Add_Click({
    $transparentBrush = New-Object System.Windows.Media.SolidColorBrush([System.Windows.Media.Color]::FromArgb(0, 0, 0, 0))
    
    # Clear all browser buttons
    $BtnBrave.Background = $transparentBrush
    $BtnChrome.Background = $transparentBrush
    $BtnChromium.Background = $transparentBrush
    $BtnEdge.Background = $transparentBrush
    $BtnFalkon.Background = $transparentBrush
    $BtnFirefox.Background = $transparentBrush
    $BtnFirefoxESR.Background = $transparentBrush
    $BtnFloorp.Background = $transparentBrush
    $BtnLibreWolf.Background = $transparentBrush
    $BtnMullvadBrowser.Background = $transparentBrush
    $BtnPaleMoon.Background = $transparentBrush
    $BtnThorium.Background = $transparentBrush
    $BtnTorBrowser.Background = $transparentBrush
    $BtnUngoogled.Background = $transparentBrush
    $BtnVivaldi.Background = $transparentBrush
    $BtnWaterfox.Background = $transparentBrush
    $BtnZenBrowser.Background = $transparentBrush
    
    # Game launchers
    $BtnSteam.Background = $transparentBrush
    $BtnEpicGames.Background = $transparentBrush
    $BtnEAApp.Background = $transparentBrush
    $BtnUbisoft.Background = $transparentBrush
    $BtnGOG.Background = $transparentBrush
    
    # Proton apps
    $BtnProtonVPN.Background = $transparentBrush
    $BtnProtonMail.Background = $transparentBrush
    $BtnProtonDrive.Background = $transparentBrush
    if ($null -ne $BtnProtonPass) { $BtnProtonPass.Background = $transparentBrush }
    
    # Development tools
    $BtnAegisub.Background = $transparentBrush
    $BtnAnaconda.Background = $transparentBrush
    $BtnClink.Background = $transparentBrush
    $BtnCMake.Background = $transparentBrush
    $BtnDaxStudio.Background = $transparentBrush
    $BtnDocker.Background = $transparentBrush
    $BtnFNM.Background = $transparentBrush
    $BtnFork.Background = $transparentBrush
    $BtnGit.Background = $transparentBrush
    $BtnGitButler.Background = $transparentBrush
    $BtnGitExtensions.Background = $transparentBrush
    $BtnGitHubCLI.Background = $transparentBrush
    $BtnGitHubDesktop.Background = $transparentBrush
    $BtnGitify.Background = $transparentBrush
    $BtnGitKraken.Background = $transparentBrush
    $BtnGodot.Background = $transparentBrush
    $BtnGo.Background = $transparentBrush
    $BtnHelix.Background = $transparentBrush
    $BtnCorretto11.Background = $transparentBrush
    $BtnCorretto17.Background = $transparentBrush
    $BtnCorretto21.Background = $transparentBrush
    $BtnCorretto8.Background = $transparentBrush
    $BtnJetbrainsToolbox.Background = $transparentBrush
    $BtnLazygit.Background = $transparentBrush
    $BtnMiniconda.Background = $transparentBrush
    $BtnMu.Background = $transparentBrush
    $BtnNeovim.Background = $transparentBrush
    $BtnNodeJS.Background = $transparentBrush
    $BtnNodeJSLTS.Background = $transparentBrush
    $BtnNVM.Background = $transparentBrush
    $BtnPixi.Background = $transparentBrush
    $BtnOhMyPosh.Background = $transparentBrush
    $BtnPostman.Background = $transparentBrush
    $BtnPulsar.Background = $transparentBrush
    $BtnPyenv.Background = $transparentBrush
    $BtnPython.Background = $transparentBrush
    $BtnRust.Background = $transparentBrush
    $BtnStarship.Background = $transparentBrush
    $BtnSublimeMerge.Background = $transparentBrush
    $BtnSublimeText.Background = $transparentBrush
    $BtnSwift.Background = $transparentBrush
    $BtnTemurin.Background = $transparentBrush
    $BtnThonny.Background = $transparentBrush
    $BtnUnity.Background = $transparentBrush
    $BtnVagrant.Background = $transparentBrush
    $BtnVisualStudio2022.Background = $transparentBrush
    $BtnVSCode.Background = $transparentBrush
    $BtnVSCodium.Background = $transparentBrush
    $BtnWezterm.Background = $transparentBrush
    $BtnYarn.Background = $transparentBrush
    
    # Media & utilities
    $BtnDiscord.Background = $transparentBrush
    $BtnSpotify.Background = $transparentBrush
    $BtnVLC.Background = $transparentBrush
    $Btn7Zip.Background = $transparentBrush
    $BtnNotepadPlusPlus.Background = $transparentBrush
    $BtnOBS.Background = $transparentBrush
    
    $script:SelectedApps.Clear()
    Write-Host "All selections cleared" -ForegroundColor Yellow
})

# Uninstall Selected Button
$BtnUninstall.Add_Click({
    $selectedApps = @($script:SelectedApps.Keys)
    
    if ($selectedApps.Count -eq 0) {
        [System.Windows.MessageBox]::Show("Please select at least one application to uninstall.", "No Selection", "OK", "Warning")
        return
    }
    
    $manager = if ($RbWinget.IsChecked) { "Winget" } else { "Chocolatey" }
    $appList = $selectedApps -join ", "
    
    $result = [System.Windows.MessageBox]::Show(
        "Are you sure you want to uninstall the following applications?`n`n$appList`n`nUsing: $manager",
        "Confirm Uninstall",
        [System.Windows.MessageBoxButton]::YesNo,
        [System.Windows.MessageBoxImage]::Warning
    )
    
    if ($result -eq [System.Windows.MessageBoxResult]::Yes) {
        Write-Host "Starting uninstall process..." -ForegroundColor Yellow
        Uninstall-Applications -Apps $selectedApps -Manager $manager
        Write-Host "Uninstall process completed" -ForegroundColor Green
        [System.Windows.MessageBox]::Show("Uninstall process completed! Check console for details.", "PC Tweaks", "OK", "Information")
    }
})

# Install/Update Selected Button
$BtnInstallUpdate.Add_Click({
    $selectedApps = @($script:SelectedApps.Keys)
    
    if ($selectedApps.Count -eq 0) {
        [System.Windows.MessageBox]::Show("Please select at least one application to install.", "No Selection", "OK", "Warning")
        return
    }
    
    $manager = if ($RbWinget.IsChecked) { "Winget" } else { "Chocolatey" }
    $appList = $selectedApps -join ", "
    
    $result = [System.Windows.MessageBox]::Show(
        "Install/Update the following applications?`n`n$appList`n`nUsing: $manager",
        "Confirm Install",
        [System.Windows.MessageBoxButton]::YesNo,
        [System.Windows.MessageBoxImage]::Question
    )
    
    if ($result -eq [System.Windows.MessageBoxResult]::Yes) {
        Write-Host "Starting install/update process..." -ForegroundColor Yellow
        Install-Applications -Apps $selectedApps -Manager $manager
        Write-Host "Install/update process completed" -ForegroundColor Green
        [System.Windows.MessageBox]::Show("Install/update process completed! Check console for details.", "PC Tweaks", "OK", "Information")
    }
})

# ===============================
# Show window
# ===============================
$window.ShowDialog() | Out-Null

# ===============================
# Config Page: Features + Fixes handlers
# ===============================
try {
    if ($null -ne $BtnInstallFeatures) {
        $BtnInstallFeatures.Add_Click({ Install-SelectedFeatures })
    }

    if ($null -ne $BtnSetupAutologin) {
        $BtnSetupAutologin.Add_Click({ Start-AutologinSetup })
    }
    if ($null -ne $BtnResetWindowsUpdate) {
        $BtnResetWindowsUpdate.Add_Click({ Reset-WindowsUpdate })
    }
    if ($null -ne $BtnResetNetwork) {
        $BtnResetNetwork.Add_Click({ Reset-NetworkStack })
    }
    if ($null -ne $BtnSystemCorruptionScan) {
        $BtnSystemCorruptionScan.Add_Click({ Invoke-SystemCorruptionScan })
    }
    if ($null -ne $BtnWinGetReinstall) {
        $BtnWinGetReinstall.Add_Click({ Repair-WinGet })
    }
    if ($null -ne $BtnRemoveAdobeCC) {
        $BtnRemoveAdobeCC.Add_Click({ Remove-AdobeCreativeCloud })
    }
} catch {
    Write-Log "ERROR wiring Config page handlers: $_"
}
