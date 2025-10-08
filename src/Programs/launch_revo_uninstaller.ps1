# Function to launch Revo Uninstaller silently
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
# Run the function
Launch_RevoSilent
