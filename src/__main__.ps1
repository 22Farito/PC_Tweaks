# ===============================
# Import all .ps1 files in src and subfolders except this file and Prefrence.ps1
# ===============================
$importMe = $MyInvocation.MyCommand.Path
$srcRoot = Split-Path $importMe
$ps1Files = Get-ChildItem -Path $srcRoot -Recurse -Filter *.ps1 | Where-Object {
    $_.FullName -ne $importMe -and $_.Name -ne '__main__.ps1' -and $_.Name -ne 'Prefrence.ps1'
}
foreach ($file in $ps1Files) {
    Write-Host "Importing $($file.FullName)"
    . $file.FullName
}
# ===============================
# XAML UI
# ===============================
$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="PCTool"
        ResizeMode="CanResize"
        MinHeight="600" MinWidth="1000"
        WindowStartupLocation="CenterScreen"
        Foreground="{DynamicResource ForegroundBrush}"
        Background="{DynamicResource WindowBackgroundBrush}">
    <Window.Resources>
        <!-- Dark theme -->
        <Color x:Key="DarkBackgroundColor">#0A0F1C</Color>
        <Color x:Key="DarkForegroundColor">White</Color>
        <Color x:Key="DarkCardColor">#801F2937</Color> <!-- 50% transparent dark card -->
        <Color x:Key="DarkBorderColor">#374151</Color>
        <Color x:Key="DarkTopBarColor">#1F2937</Color>
        <!-- Light theme -->
        <Color x:Key="LightBackgroundColor">#F5F5F5</Color>
        <Color x:Key="LightForegroundColor">#111111</Color>
        <Color x:Key="LightCardColor">#80FFFFFF</Color> <!-- 50% transparent white card -->
        <Color x:Key="LightBorderColor">#CCCCCC</Color>
        <Color x:Key="LightTopBarColor">#FFFFFF</Color>
        <!-- Active theme (start with dark) -->
        <SolidColorBrush x:Key="WindowBackgroundBrush" Color="{StaticResource DarkBackgroundColor}"/>
        <SolidColorBrush x:Key="ForegroundBrush"       Color="{StaticResource DarkForegroundColor}"/>
        <SolidColorBrush x:Key="CardBrush"             Color="{StaticResource DarkCardColor}"/>
        <SolidColorBrush x:Key="BorderBrushColor"      Color="{StaticResource DarkBorderColor}"/>
        <SolidColorBrush x:Key="TopBarBrush"           Color="{StaticResource DarkTopBarColor}"/>
        <ImageBrush x:Key="NoiseBrush"/>
        <!-- Accent for toggles -->
        <SolidColorBrush x:Key="AccentBrush" Color="#4F8EF7"/>
        <!-- Toggle Switch Style -->
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
        <!-- Button Style -->
        <Style x:Key="RoundedNavButton" TargetType="Button">
            <Setter Property="FontWeight" Value="Bold"/>
            <Setter Property="FontSize" Value="18"/>
            <Setter Property="Width" Value="130"/>
            <Setter Property="Height" Value="48"/>
            <Setter Property="Margin" Value="7"/>
            <Setter Property="Foreground" Value="{DynamicResource ForegroundBrush}"/>
            <Setter Property="Background" Value="{DynamicResource CardBrush}"/>
            <Setter Property="BorderBrush" Value="{DynamicResource BorderBrushColor}"/>
            <Setter Property="BorderThickness" Value="2"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border Background="{TemplateBinding Background}" 
                                BorderBrush="{TemplateBinding BorderBrush}" 
                                BorderThickness="{TemplateBinding BorderThickness}" 
                                CornerRadius="16">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter Property="Background" Value="#22FFFFFF"/>
                                <Setter Property="BorderBrush" Value="#FF4F8EF7"/>
                                <Setter Property="BorderThickness" Value="3"/>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter Property="Background" Value="#22000000"/>
                                <Setter Property="BorderBrush" Value="#FF2563EB"/>
                                <Setter Property="BorderThickness" Value="3"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
        <!-- Button for tweaks -->
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
                        <Border Background="{TemplateBinding Background}" 
                                BorderBrush="{TemplateBinding BorderBrush}" 
                                BorderThickness="{TemplateBinding BorderThickness}" 
                                CornerRadius="11">
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
        <Rectangle Fill="{DynamicResource WindowBackgroundBrush}" HorizontalAlignment="Stretch" VerticalAlignment="Stretch"/>
        <Rectangle Fill="{DynamicResource NoiseBrush}" Opacity="0.8" HorizontalAlignment="Stretch" VerticalAlignment="Stretch"/>
        <Grid>
            <Grid.RowDefinitions>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="*"/>
            </Grid.RowDefinitions>
            <!-- Top Nav -->
            <DockPanel Name="TopNavPanel" Background="{DynamicResource TopBarBrush}" Grid.Row="0" LastChildFill="False">
                <StackPanel Orientation="Horizontal" HorizontalAlignment="Center" VerticalAlignment="Center">
                    <Button Name="BtnHome"     Content="Home"     Style="{StaticResource RoundedNavButton}"/>
                    <Button Name="BtnInstall"  Content="Install"  Style="{StaticResource RoundedNavButton}"/>
                    <Button Name="BtnTweaks"   Content="Tweaks"   Style="{StaticResource RoundedNavButton}"/>
                    <Button Name="BtnConfig"   Content="Config"   Style="{StaticResource RoundedNavButton}"/>
                    <Button Name="BtnPrograms" Content="Programs" Style="{StaticResource RoundedNavButton}"/>
                    <Button Name="BtnLogs"     Content="Logs"     Style="{StaticResource RoundedNavButton}"/>
                </StackPanel>
                <Button Name="BtnToggleTheme" Content="🌗" Width="48" Height="48"
                        Margin="10" HorizontalAlignment="Right" VerticalAlignment="Center"
                        DockPanel.Dock="Right"
                        Style="{StaticResource RoundedNavButton}"/>
            </DockPanel>
            <!-- Main Pages -->
            <Grid Grid.Row="1" Margin="0,0,0,0">
                <!-- Home Page -->
                <Grid Name="PageHome" Margin="10">
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*" />
                        <ColumnDefinition Width="*" />
                    </Grid.ColumnDefinitions>
                    <!-- PC Info -->
                    <Border Background="{DynamicResource CardBrush}"
                            BorderBrush="{DynamicResource BorderBrushColor}"
                            BorderThickness="2" CornerRadius="8" Margin="10" Grid.Column="0">
                        <StackPanel Margin="15">
                            <TextBlock Text="PC Information" FontSize="20" FontWeight="Bold" Margin="0,0,0,10"/>
                            <Separator Margin="0,5"/>
                            <TextBlock Name="LblOS"   FontSize="16" Margin="0,5"/>
                            <TextBlock Name="LblCPU"  FontSize="16" Margin="0,5"/>
                            <TextBlock Name="LblRAM"  FontSize="16" Margin="0,5"/>
                            <TextBlock Name="LblGPU"  FontSize="16" Margin="0,5"/>
                            <TextBlock Name="LblMotherboard" FontSize="16" Margin="0,5"/>
                            <TextBlock Name="LblBIOS" FontSize="16" Margin="0,5"/>
                            <TextBlock Name="LblDisk" FontSize="16" Margin="0,5"/>
                            <TextBlock Name="LblNetwork" FontSize="16" Margin="0,5"/>
                            <TextBlock Name="LblSound" FontSize="16" Margin="0,5"/>
                        </StackPanel>
                    </Border>
                    <!-- Advanced Info -->
                    <Border Background="{DynamicResource CardBrush}"
                            BorderBrush="{DynamicResource BorderBrushColor}"
                            BorderThickness="2" CornerRadius="8" Margin="10" Grid.Column="1">
                        <Grid>
                            <Grid.RowDefinitions>
                                <RowDefinition Height="Auto"/>
                                <RowDefinition Height="*"/>
                            </Grid.RowDefinitions>
                            <DockPanel Grid.Row="0" LastChildFill="True">
                                <TextBlock Text="Advanced Info" FontSize="20" FontWeight="Bold" Margin="15,0,0,10" VerticalAlignment="Center"/>
                                <Button Name="BtnToggleAdvanced" Content="🙈" Width="30" Height="30" 
                                        DockPanel.Dock="Right" Margin="0,0,10,0" VerticalAlignment="Center"/>
                            </DockPanel>
                            <StackPanel Margin="15" Grid.Row="1">
                                <Separator Margin="0,5"/>
                                <TextBlock Name="LblRouterIP" FontSize="16" Margin="0,5"/>
                                <TextBlock Name="LblIP"       FontSize="16" Margin="0,5"/>
                                <TextBlock Name="LblMAC"      FontSize="16" Margin="0,5"/>
                                <TextBlock Name="LblHWID"     FontSize="16" Margin="0,5"/>
                                <TextBlock Name="LblPublicIP" FontSize="16" Margin="0,5"/>
                            </StackPanel>
                        </Grid>
                    </Border>
                </Grid>
                <!-- Tweaks Page -->
                <Grid Name="PageTweaks" Visibility="Collapsed" Margin="10">
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="2.7*"/>
                        <ColumnDefinition Width="2.3*"/>
                    </Grid.ColumnDefinitions>
                    <Grid.RowDefinitions>
                        <RowDefinition Height="*"/>
                    </Grid.RowDefinitions>
                    <!-- Advanced Tweaks (Left) -->
                    <Border Grid.Column="0" Margin="12,8,12,8" Background="{DynamicResource CardBrush}" CornerRadius="12" BorderThickness="1" BorderBrush="{DynamicResource BorderBrushColor}">
                        <Grid>
                            <Grid.RowDefinitions>
                                <RowDefinition Height="*"/>
                                <RowDefinition Height="Auto"/>
                            </Grid.RowDefinitions>
                            <ScrollViewer Grid.Row="0" VerticalScrollBarVisibility="Auto">
                                <StackPanel Margin="24">
                                <CheckBox Name="ChkTweak1"  Content="Placeholder Tweak 1"  Style="{StaticResource ToggleSwitchStyle}" Margin="0,0,0,10"/>
                                <CheckBox Name="ChkTweak2"  Content="Placeholder Tweak 2"  Style="{StaticResource ToggleSwitchStyle}" Margin="0,0,0,10"/>
                                <CheckBox Name="ChkTweak3"  Content="Placeholder Tweak 3"  Style="{StaticResource ToggleSwitchStyle}" Margin="0,0,0,10"/>
                                <CheckBox Name="ChkTweak4"  Content="Placeholder Tweak 4"  Style="{StaticResource ToggleSwitchStyle}" Margin="0,0,0,10"/>
                                <CheckBox Name="ChkTweak5"  Content="Placeholder Tweak 5"  Style="{StaticResource ToggleSwitchStyle}" Margin="0,0,0,10"/>
                                <CheckBox Name="ChkTweak6"  Content="Placeholder Tweak 6"  Style="{StaticResource ToggleSwitchStyle}" Margin="0,0,0,10"/>
                                <CheckBox Name="ChkTweak7"  Content="Placeholder Tweak 7"  Style="{StaticResource ToggleSwitchStyle}" Margin="0,0,0,10"/>
                                <CheckBox Name="ChkTweak8"  Content="Placeholder Tweak 8"  Style="{StaticResource ToggleSwitchStyle}" Margin="0,0,0,10"/>
                                <CheckBox Name="ChkTweak9"  Content="Placeholder Tweak 9"  Style="{StaticResource ToggleSwitchStyle}" Margin="0,0,0,10"/>
                                <CheckBox Name="ChkTweak10" Content="Placeholder Tweak 10" Style="{StaticResource ToggleSwitchStyle}" Margin="0,0,0,10"/>
                                <CheckBox Name="ChkTweak11" Content="Placeholder Tweak 11" Style="{StaticResource ToggleSwitchStyle}" Margin="0,0,0,10"/>
                                <CheckBox Name="ChkTweak12" Content="Placeholder Tweak 12" Style="{StaticResource ToggleSwitchStyle}" Margin="0,0,0,10"/>
                                <CheckBox Name="ChkTweak13" Content="Placeholder Tweak 13" Style="{StaticResource ToggleSwitchStyle}" Margin="0,0,0,10"/>
                                <CheckBox Name="ChkTweak14" Content="Placeholder Tweak 14" Style="{StaticResource ToggleSwitchStyle}" Margin="0,0,0,10"/>
                                <CheckBox Name="ChkTweak15" Content="Placeholder Tweak 15" Style="{StaticResource ToggleSwitchStyle}" Margin="0,0,0,10"/>
                                <CheckBox Name="ChkTweak16" Content="Placeholder Tweak 16" Style="{StaticResource ToggleSwitchStyle}" Margin="0,0,0,10"/>
                                <CheckBox Name="ChkTweak17" Content="Placeholder Tweak 17" Style="{StaticResource ToggleSwitchStyle}" Margin="0,0,0,10"/>
                                <CheckBox Name="ChkTweak18" Content="Placeholder Tweak 18" Style="{StaticResource ToggleSwitchStyle}" Margin="0,0,0,10"/>
                                <CheckBox Name="ChkTweak19" Content="Placeholder Tweak 19" Style="{StaticResource ToggleSwitchStyle}" Margin="0,0,0,10"/>
                                <CheckBox Name="ChkTweak20" Content="Placeholder Tweak 20" Style="{StaticResource ToggleSwitchStyle}" Margin="0,0,0,10"/>
                                </StackPanel>
                            </ScrollViewer>
                            <StackPanel Grid.Row="1">
                                <Button Name="BtnSetGameProfile" Content="Set Game Profile" Style="{StaticResource RoundedButton}" Margin="24,10,24,0" Height="44"/>
                                <Button Name="BtnRunTweaks" Content="Run Tweaks" Style="{StaticResource RoundedButton}" Margin="24,20,24,24" Height="44"/>
                            </StackPanel>
                        </Grid>
                    </Border>
                    <!-- Right Side: Preferences + Set/Remove Buttons -->
                    <StackPanel Grid.Column="1" Margin="0,8,12,8">
                        <Border Background="{DynamicResource CardBrush}" CornerRadius="12" BorderThickness="1" BorderBrush="{DynamicResource BorderBrushColor}" Margin="0,0,0,16">
                            <StackPanel Margin="24">
                                <TextBlock Text="Customize Preferences" FontSize="21" FontWeight="Bold" Foreground="{DynamicResource ForegroundBrush}" Margin="0,0,0,16"/>
                                <!-- Toggle Switches with padding -->
                                <CheckBox Content="Dark Theme for Windows" Style="{StaticResource ToggleSwitchStyle}" IsChecked="True" Margin="0,0,0,10"/>
                                <CheckBox Content="Bing Search in Start Menu" Style="{StaticResource ToggleSwitchStyle}" IsChecked="True" Margin="0,0,0,10"/>
                                <CheckBox Content="NumLock on Startup" Style="{StaticResource ToggleSwitchStyle}" IsChecked="True" Margin="0,0,0,10"/>
                                <CheckBox Content="Verbose Messages During Logon" Style="{StaticResource ToggleSwitchStyle}" Margin="0,0,0,10"/>
                                <CheckBox Content="Recommendations in Start Menu" Style="{StaticResource ToggleSwitchStyle}" Margin="0,0,0,10"/>
                                <CheckBox Content="Remove Settings Home Page" Style="{StaticResource ToggleSwitchStyle}" Margin="0,0,0,10"/>
                                <CheckBox Content="Snap Window" Style="{StaticResource ToggleSwitchStyle}" IsChecked="True" Margin="0,0,0,10"/>
                                <CheckBox Content="Snap Assist Flyout" Style="{StaticResource ToggleSwitchStyle}" IsChecked="True" Margin="0,0,0,10"/>
                                <CheckBox Content="Snap Assist Suggestion" Style="{StaticResource ToggleSwitchStyle}" Margin="0,0,0,10"/>
                                <CheckBox Name="ChkMouseAcceleration" Content="Mouse Acceleration" Style="{StaticResource ToggleSwitchStyle}" Margin="0,0,0,10"/>
                                <CheckBox Content="Sticky Keys" Style="{StaticResource ToggleSwitchStyle}" Margin="0,0,0,10"/>
                                <CheckBox Content="Show Hidden Files" Style="{StaticResource ToggleSwitchStyle}" IsChecked="True" Margin="0,0,0,10"/>
                                <CheckBox Content="Show File Extensions" Style="{StaticResource ToggleSwitchStyle}" IsChecked="True" Margin="0,0,0,10"/>
                                <CheckBox Content="Search Button in Taskbar" Style="{StaticResource ToggleSwitchStyle}" Margin="0,0,0,10"/>
                                <CheckBox Content="Task View Button in Taskbar" Style="{StaticResource ToggleSwitchStyle}" Margin="0,0,0,10"/>
                                <CheckBox Content="Center Taskbar Items" Style="{StaticResource ToggleSwitchStyle}" Margin="0,0,0,10"/>
                                <CheckBox Content="Widgets Button in Taskbar" Style="{StaticResource ToggleSwitchStyle}" Margin="0,0,0,10"/>
                                <CheckBox Content="Detailed BsOD" Style="{StaticResource ToggleSwitchStyle}" Margin="0,0,0,10"/>
                                <CheckBox Content="S3 Sleep" Style="{StaticResource ToggleSwitchStyle}" Margin="0,0,0,10"/>
                            </StackPanel>
                        </Border>
                        <Border Background="{DynamicResource CardBrush}" CornerRadius="12" BorderThickness="1" BorderBrush="{StaticResource BorderBrushColor}">
                            <StackPanel Margin="24">
                                <TextBlock Text="Reg &amp; Services" FontSize="20" FontWeight="Bold" Foreground="{DynamicResource ForegroundBrush}" Margin="0,0,0,13"/>
                                <Button Name="BtnSetRegTweaks" Content="Set Registry Tweaks" Style="{StaticResource RoundedButton}" Margin="0,2,0,7"/>
                                <Button Name="BtnSetServiceTweaks" Content="Set Service Tweaks" Style="{StaticResource RoundedButton}" Margin="0,2,0,7"/>
                            </StackPanel>
                        </Border>
                    </StackPanel>
                </Grid>
                <!-- Logs Page -->
                <Grid Name="PageLogs" Visibility="Collapsed" Margin="10">
                    <Border Background="{DynamicResource CardBrush}" BorderBrush="{DynamicResource BorderBrushColor}" BorderThickness="1" CornerRadius="8">
                        <Grid>
                            <Grid.RowDefinitions>
                                <RowDefinition Height="*" />
                                <RowDefinition Height="Auto" />
                            </Grid.RowDefinitions>
                            <ScrollViewer Grid.Row="0" Margin="16,16,16,0" VerticalScrollBarVisibility="Auto">
                                <TextBox Name="TxtLogs" FontFamily="Consolas" FontSize="14"
                                         Foreground="{DynamicResource ForegroundBrush}"
                                         Background="{DynamicResource CardBrush}"
                                         BorderThickness="0"
                                         IsReadOnly="True"
                                         VerticalScrollBarVisibility="Auto"
                                         Text="Logs will appear here..." />
                            </ScrollViewer>
                            <StackPanel Grid.Row="1" Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,0,16,16">
                                <Button Name="BtnDownloadLogs" Content="Download Logs" Style="{StaticResource RoundedNavButton}"/>
                            </StackPanel>
                        </Grid>
                    </Border>
                    <!-- Other Pages -->
                    <Grid Name="PageInstall"  Visibility="Collapsed"><TextBlock Text="Install Page"  FontSize="28" HorizontalAlignment="Center" VerticalAlignment="Center"/></Grid>
                    <Grid Name="PageConfig"   Visibility="Collapsed"><TextBlock Text="Config Page"   FontSize="28" HorizontalAlignment="Center" VerticalAlignment="Center"/></Grid>
                    <Grid Name="PagePrograms" Visibility="Collapsed"><TextBlock Text="Programs Page" FontSize="28" HorizontalAlignment="Center" VerticalAlignment="Center"/></Grid>
                </Grid>
            </Grid>
        </Grid>
    </Grid>
</Window>
"@

# ===============================
# Load XAML
# ===============================
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
# Find UI Elements
# ===============================
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
# Logging Function
# ===============================
function Write-Log($message) {
    $logFilePath = Join-Path $PSScriptRoot "logs.txt"
    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Add-Content -Path $logFilePath -Value "[$timestamp] $message"
}

# ===============================
# Import Mouse Acceleration Logic
# ===============================
. "$PSScriptRoot\Tweaks\Prefrence.ps1"


# ===============================
# Logs Button Logic
# ===============================
$BtnLogs.Add_Click({
    Show-Page $PageLogs
    $logFilePath = Join-Path $PSScriptRoot "logs.txt"
    if (Test-Path $logFilePath) {
        $TxtLogs.Text = Get-Content $logFilePath -Raw
    } else {
        $TxtLogs.Text = "No log file found."
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
    if ($global:darkMode) {
        $window.Resources["WindowBackgroundBrush"] = [System.Windows.Media.SolidColorBrush]$window.Resources["LightBackgroundColor"]
        $window.Resources["ForegroundBrush"]       = [System.Windows.Media.SolidColorBrush]$window.Resources["LightForegroundColor"]
        $window.Resources["CardBrush"]             = [System.Windows.Media.SolidColorBrush]$window.Resources["LightCardColor"]
        $window.Resources["BorderBrushColor"]      = [System.Windows.Media.SolidColorBrush]$window.Resources["LightBorderColor"]
        $window.Resources["TopBarBrush"]           = [System.Windows.Media.SolidColorBrush]$window.Resources["LightTopBarColor"]
        $TopNavPanel.Background = $window.Resources["TopBarBrush"]
        $global:darkMode = $false
    } else {
        $window.Resources["WindowBackgroundBrush"] = [System.Windows.Media.SolidColorBrush]$window.Resources["DarkBackgroundColor"]
        $window.Resources["ForegroundBrush"]       = [System.Windows.Media.SolidColorBrush]$window.Resources["DarkForegroundColor"]
        $window.Resources["CardBrush"]             = [System.Windows.Media.SolidColorBrush]$window.Resources["DarkCardColor"]
        $window.Resources["BorderBrushColor"]      = [System.Windows.Media.SolidColorBrush]$window.Resources["DarkBorderColor"]
        $window.Resources["TopBarBrush"]           = [System.Windows.Media.SolidColorBrush]$window.Resources["DarkTopBarColor"]
        $TopNavPanel.Background = $window.Resources["TopBarBrush"]
        $global:darkMode = $true
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