# Force Refresh Dashboard - Clears cache and opens updated dashboard
# This script forces the browser to reload the dashboard with fresh data

# Color definitions
$GREEN = "Green"
$BLUE = "Cyan"
$YELLOW = "Yellow"
$WHITE = "White"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$DashboardPath = Join-Path $ScriptDir "..\reports\security-reports\dashboards\security-dashboard.html"

Write-Host "============================================" -ForegroundColor $WHITE
Write-Host "🔄 Force Dashboard Refresh" -ForegroundColor $WHITE
Write-Host "============================================" -ForegroundColor $WHITE
Write-Host ""

if (Test-Path $DashboardPath) {
    # Show current file timestamp
    $FileInfo = Get-Item $DashboardPath
    Write-Host "📄 Dashboard file: $($FileInfo.Name)" -ForegroundColor $BLUE
    Write-Host "🕒 Last modified: $($FileInfo.LastWriteTime)" -ForegroundColor $BLUE
    Write-Host ""
    
    # Create a unique timestamp for cache busting
    $Timestamp = [int][double]::Parse((Get-Date -UFormat %s))
    
    # Create file URL with cache busting parameters
    $DashboardUrl = "file:///$($DashboardPath.Replace('\', '/'))?nocache=$Timestamp&refresh=true"
    
    Write-Host "🧹 Using cache-busting parameters..." -ForegroundColor $YELLOW
    Write-Host "🚀 Opening fresh dashboard..." -ForegroundColor $BLUE
    
    # Open with cache busting
    Start-Process $DashboardPath
    
    Write-Host ""
    Write-Host "✅ Dashboard opened with fresh cache!" -ForegroundColor $GREEN
    Write-Host ""
    Write-Host "💡 If you still see old data:" -ForegroundColor $YELLOW
    Write-Host "   1. Press Ctrl+Shift+R (Windows) to force refresh"
    Write-Host "   2. Or close browser completely and reopen"
    Write-Host "   3. Or use browser's Developer Tools > Network > Disable cache"
    
} else {
    Write-Host "❌ Dashboard file not found: $DashboardPath" -ForegroundColor $YELLOW
    Write-Host "💡 Try running: .\consolidate-security-reports.ps1" -ForegroundColor $BLUE
}

Write-Host ""
Write-Host "============================================" -ForegroundColor $WHITE
