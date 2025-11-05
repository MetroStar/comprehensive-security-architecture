# Portable Scanner Demo Script
# Demonstrates how to use the portable security scanner on different applications

# Color definitions
$GREEN = "Green"
$BLUE = "Cyan"
$YELLOW = "Yellow"
$WHITE = "White"

$ScannerScript = ".\portable-app-scanner.ps1"

Write-Host "============================================" -ForegroundColor $WHITE
Write-Host "🎯 Portable Security Scanner Demonstration" -ForegroundColor $WHITE
Write-Host "============================================" -ForegroundColor $WHITE
Write-Host ""

# Demo 1: Quick scan of the original marketplace app
Write-Host "📋 Demo 1: Quick scan of original marketplace application" -ForegroundColor $BLUE
Write-Host "Command: $ScannerScript C:\Users\rnelson\Desktop\CDAO MarketPlace\Marketplace\advana-marketplace quick" -ForegroundColor $YELLOW
Write-Host ""

Read-Host "Press Enter to run quick scan demo..."

& $ScannerScript "C:\Users\rnelson\Desktop\CDAO MarketPlace\Marketplace\advana-marketplace" quick

Write-Host ""
Write-Host "✅ Demo 1 completed!" -ForegroundColor $GREEN
Write-Host ""

# Demo 2: Secrets-only scan
Write-Host "📋 Demo 2: Secrets-only scan" -ForegroundColor $BLUE
Write-Host "Command: $ScannerScript C:\Users\rnelson\Desktop\CDAO MarketPlace\Marketplace\advana-marketplace secrets-only" -ForegroundColor $YELLOW
Write-Host ""

Read-Host "Press Enter to run secrets-only scan demo..."

& $ScannerScript "C:\Users\rnelson\Desktop\CDAO MarketPlace\Marketplace\advana-marketplace" secrets-only --output-dir C:\Temp\secrets-scan-demo

Write-Host ""
Write-Host "✅ Demo 2 completed!" -ForegroundColor $GREEN
Write-Host ""

# Demo 3: Show how to scan any directory
Write-Host "📋 Demo 3: How to scan any application directory" -ForegroundColor $BLUE
Write-Host ""
Write-Host "Examples of how to use the portable scanner:" -ForegroundColor $YELLOW
Write-Host ""
Write-Host "# Scan any Node.js application:"
Write-Host "$ScannerScript C:\path\to\nodejs-app"
Write-Host ""
Write-Host "# Scan any Python application:"
Write-Host "$ScannerScript C:\path\to\python-app vulns-only"
Write-Host ""
Write-Host "# Scan with custom output directory:"
Write-Host "$ScannerScript C:\path\to\any-app full --output-dir C:\custom\output\path"
Write-Host ""
Write-Host "# Quick security check:"
Write-Host "$ScannerScript C:\path\to\app quick"
Write-Host ""
Write-Host "# Check for secrets only:"
Write-Host "$ScannerScript C:\path\to\app secrets-only"
Write-Host ""
Write-Host "# Infrastructure security only:"
Write-Host "$ScannerScript C:\path\to\kubernetes-app iac-only"

Write-Host ""
Write-Host "============================================" -ForegroundColor $WHITE
Write-Host "🎉 Portable Scanner Demo Complete!" -ForegroundColor $GREEN
Write-Host "============================================" -ForegroundColor $WHITE
Write-Host ""
Write-Host "💡 Key Features:" -ForegroundColor $BLUE
Write-Host "✅ Scans any application directory"
Write-Host "✅ Auto-detects application type (Node.js, Python, Java, etc.)"
Write-Host "✅ Multiple scan types (full, quick, secrets-only, etc.)"
Write-Host "✅ Docker-based tools for consistency"
Write-Host "✅ Generates comprehensive reports"
Write-Host "✅ Works on any filesystem location"
Write-Host ""
Write-Host "🚀 Ready to scan any application!" -ForegroundColor $BLUE
