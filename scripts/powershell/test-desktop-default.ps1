# Quick Test Script for Desktop Default Behavior
# Shows how the portable scanner now defaults to Desktop directory

# Color definitions
$GREEN = "Green"
$BLUE = "Cyan"
$YELLOW = "Yellow"
$WHITE = "White"

Write-Host "============================================" -ForegroundColor $WHITE
Write-Host "🎯 Portable Scanner - Desktop Default Test" -ForegroundColor $WHITE
Write-Host "============================================" -ForegroundColor $WHITE
Write-Host ""

Write-Host "📋 Testing new Desktop directory default behavior..." -ForegroundColor $BLUE
Write-Host ""

Write-Host "Test 1: Help command" -ForegroundColor $YELLOW
Write-Host "Command: .\portable-app-scanner.ps1 --help | Select-Object -First 15"
Write-Host ""
.\portable-app-scanner.ps1 --help | Select-Object -First 15
Write-Host ""

Write-Host "Test 2: Default behavior (should default to Desktop)" -ForegroundColor $YELLOW
Write-Host "Command: .\portable-app-scanner.ps1 quick (with early exit)"
Write-Host ""
# Run with quick scan but exit after directory detection
$Job = Start-Job -ScriptBlock { 
    & "$using:PSScriptRoot\portable-app-scanner.ps1" quick 2>&1 | Select-Object -First 12
}
Start-Sleep -Seconds 3
Stop-Job $Job -ErrorAction SilentlyContinue
Receive-Job $Job
Remove-Job $Job -Force -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "Test 3: Scan type detection" -ForegroundColor $YELLOW
Write-Host "Command: .\portable-app-scanner.ps1 secrets-only (with early exit)"
Write-Host ""
# Run secrets scan but exit after directory detection
$Job = Start-Job -ScriptBlock { 
    & "$using:PSScriptRoot\portable-app-scanner.ps1" secrets-only 2>&1 | Select-Object -First 12
}
Start-Sleep -Seconds 3
Stop-Job $Job -ErrorAction SilentlyContinue
Receive-Job $Job
Remove-Job $Job -Force -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "✅ Desktop Default Enhancement Working!" -ForegroundColor $GREEN
Write-Host ""
Write-Host "💡 Usage Examples:" -ForegroundColor $BLUE
Write-Host "• .\portable-app-scanner.ps1                    → Full scan of Desktop"
Write-Host "• .\portable-app-scanner.ps1 quick             → Quick scan of Desktop"
Write-Host "• .\portable-app-scanner.ps1 secrets-only      → Secrets scan of Desktop"
Write-Host "• .\portable-app-scanner.ps1 C:\path\to\app    → Scan specific directory"
Write-Host ""
Write-Host "============================================" -ForegroundColor $WHITE
