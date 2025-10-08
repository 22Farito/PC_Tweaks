# Function to launch Revo Reg Cleaner portable
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
<#
# Run the function
Launch_RevoRegPortable
#>