# Utility function to run system commands
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

# Disable IPv6 function
function Disable-IPv6 {
    Write-Host "Disabling IPv6..." -ForegroundColor Cyan
    Run-Command "netsh interface ipv6 set disabledcomponents 0xFF"
}
<#
# Main
Disable-IPv6
#>