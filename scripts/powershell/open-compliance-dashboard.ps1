# Compliance Dashboard Launcher (PowerShell)
# Opens the security compliance dashboard for audit tracking and user activity monitoring

# Color definitions
$GREEN = "Green"
$BLUE = "Cyan"
$YELLOW = "Yellow" 
$WHITE = "White"
$RED = "Red"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent (Split-Path -Parent $ScriptDir)
$ComplianceDir = Join-Path $ProjectRoot "reports\security-reports\compliance"
$DashboardPath = Join-Path $ComplianceDir "compliance-dashboard.html"

Write-Host "============================================" -ForegroundColor $WHITE
Write-Host "🛡️  Security Compliance Dashboard Launcher" -ForegroundColor $WHITE
Write-Host "============================================" -ForegroundColor $WHITE
Write-Host ""

# Check if compliance directory exists
if (-not (Test-Path $ComplianceDir)) {
    Write-Host "⚠️  Compliance directory not found. Creating it..." -ForegroundColor $YELLOW
    New-Item -ItemType Directory -Path $ComplianceDir -Force | Out-Null
}

# Check if dashboard exists, if not generate it
if (-not (Test-Path $DashboardPath)) {
    Write-Host "📊 Compliance dashboard not found. Generating it..." -ForegroundColor $YELLOW
    
    # Check if compliance logger exists
    $ComplianceLogger = Join-Path $ScriptDir "compliance-logger.ps1"
    if (Test-Path $ComplianceLogger) {
        # Run the compliance logger to generate dashboard
        & $ComplianceLogger
    } else {
        Write-Host "❌ Error: compliance-logger.ps1 not found!" -ForegroundColor $RED
        Write-Host "Please ensure the compliance logger script is in the same directory."
        exit 1
    }
}

if (Test-Path $DashboardPath) {
    Write-Host "✅ Compliance dashboard found: $DashboardPath" -ForegroundColor $GREEN
    Write-Host "🚀 Opening compliance dashboard..." -ForegroundColor $BLUE
    
    # Add cache-busting parameter to force browser refresh
    $Timestamp = [int][double]::Parse((Get-Date -UFormat %s))
    $DashboardUrl = "file:///$($DashboardPath.Replace('\', '/'))?v=$Timestamp"
    
    # Open the dashboard in default browser
    try {
        Start-Process $DashboardPath
    } catch {
        Write-Host "💡 Please open the following file in your browser:" -ForegroundColor $BLUE
        Write-Host "   file:///$($DashboardPath.Replace('\', '/'))"
    }
    
    Write-Host ""
    Write-Host "✅ Compliance dashboard launched!" -ForegroundColor $GREEN
    Write-Host ""
    Write-Host "📊 Dashboard Features:" -ForegroundColor $BLUE
    Write-Host "• Real-time audit activity tracking"
    Write-Host "• User identification and role detection" 
    Write-Host "• Security scan compliance scoring"
    Write-Host "• Historical activity timeline"
    Write-Host "• Enterprise-grade audit trails"
    Write-Host "• CSV export for compliance reporting"
    Write-Host ""
    Write-Host "💡 Dashboard Tips:" -ForegroundColor $BLUE
    Write-Host "• Run security scans to see activity data"
    Write-Host "• Use .\audit-logger.ps1 for manual audit entries"
    Write-Host "• Export compliance reports for audits"
    Write-Host "• Monitor user activity patterns"
    Write-Host ""
    Write-Host "📁 Related Files:" -ForegroundColor $YELLOW
    Write-Host "• Dashboard: $DashboardPath"
    Write-Host "• Audit CSV:  $(Join-Path $ComplianceDir 'security-audit.csv')"
    Write-Host "• Logger:     $(Join-Path $ScriptDir 'compliance-logger.ps1')"
    
} else {
    Write-Host "❌ Error: Could not create or find compliance dashboard!" -ForegroundColor $RED
    Write-Host "Please check permissions and try running the compliance logger manually:"
    Write-Host "   .\compliance-logger.ps1"
    exit 1
}