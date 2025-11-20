<#
.SYNOPSIS
    Script Cleanup for 8-Step Security Scan
    
.DESCRIPTION
    Removes unnecessary scripts and keeps only the essential ones
    This is the PowerShell equivalent of cleanup-scripts.sh
    
.NOTES
    PowerShell version of cleanup-scripts.sh
    Note: cleanup-powershell-scripts.ps1 is the PowerShell-specific version
#>

# Set up paths
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$BashDir = $ScriptDir

Write-Host "🧹 Cleaning up scripts directory for 8-step security scan..." -ForegroundColor Blue
Write-Host ""

# Essential scripts that MUST be kept for the 8-step security scan
$EssentialScripts = @(
    # Core orchestration
    "run-target-security-scan.ps1"
    
    # 8 Security Layers
    "run-trufflehog-scan.ps1"        # Layer 1: Secret Detection
    "run-clamav-scan.ps1"            # Layer 2: Malware Detection  
    "run-checkov-scan.ps1"           # Layer 3: Infrastructure Security
    "run-grype-scan.ps1"             # Layer 4: Vulnerability Detection
    "run-trivy-scan.ps1"             # Layer 5: Container Security
    "run-xeol-scan.ps1"              # Layer 6: End-of-Life Detection
    "run-sonar-analysis.ps1"         # Layer 7: Code Quality Analysis
    "run-helm-build.ps1"             # Layer 8: Helm Chart Building
    
    # Summary and analysis
    "generate-critical-high-summary.ps1"
    "consolidate-security-reports.ps1"
    
    # Essential utilities
    "README.md"
)

# Additional clean versions (backup scripts)
$CleanScripts = @(
    "run-trufflehog-scan-clean.ps1"
    "run-clamav-scan-clean.ps1"
    "run-checkov-scan-clean.ps1"
    "run-grype-scan-clean.ps1"
    "run-trivy-scan-clean.ps1"
    "run-xeol-scan-clean.ps1"
    "run-helm-build-clean.ps1"
)

# Scripts to remove (legacy, duplicates, or unnecessary)
$RemoveScripts = @(
    # Legacy/broken versions
    "run-trufflehog-scan.ps1.broken"
    "run-trivy-scan-fixed.ps1"
    
    # Individual analysis scripts (replaced by consolidate-security-reports.ps1)
    "analyze-checkov-results.ps1"
    "analyze-clamav-results.ps1" 
    "analyze-grype-results.ps1"
    "analyze-helm-results.ps1"
    "analyze-trivy-results.ps1"
    "analyze-trufflehog-results.ps1"
    "analyze-xeol-results.ps1"
    
    # Demo and test scripts
    "demo-portable-scanner.ps1"
    "portable-app-scanner.ps1"
    "test-desktop-default.ps1"
    "test-path-resolution.ps1"
    
    # Specialized/niche scripts
    "nodejs-security-scanner.ps1"
    "real-nodejs-scanner.ps1"
    "real-nodejs-scanner-fixed.ps1"
    "example-audited-checkov.ps1"
    
    # Complete scan alternatives (redundant with run-target-security-scan.ps1)
    "run-complete-security-scan.ps1"
    
    # AWS/cloud specific utilities 
    "aws-ecr-helm-auth.ps1"
    "aws-ecr-helm-auth-guide.ps1"
    
    # Utility scripts that are less essential
    "audit-logger.ps1"
    "compliance-logger.ps1"
    "create-stub-dependencies.ps1"
    "resolve-helm-dependencies.ps1"
    "priority-issues-summary.txt"
)

# Backup important files before cleanup
$BackupDir = Join-Path $BashDir "backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
Write-Host "📦 Creating backup at: $BackupDir" -ForegroundColor Yellow
$null = New-Item -ItemType Directory -Path $BackupDir -Force

# Create backup of scripts we're about to remove
foreach ($Script in $RemoveScripts) {
    $FilePath = Join-Path $BashDir $Script
    if (Test-Path $FilePath) {
        Copy-Item $FilePath $BackupDir -ErrorAction SilentlyContinue
        Write-Host "  📄 Backed up: $Script"
    }
}

Write-Host "✅ Backup completed" -ForegroundColor Green
Write-Host ""

# Remove unnecessary scripts
Write-Host "🗑️  Removing unnecessary scripts..." -ForegroundColor Red
$RemovedCount = 0

foreach ($Script in $RemoveScripts) {
    $FilePath = Join-Path $BashDir $Script
    if (Test-Path $FilePath) {
        Remove-Item $FilePath -Force
        Write-Host "  ❌ Removed: $Script"
        $RemovedCount++
    }
}

# Also remove any exclude-paths.txt directory if it exists
$ExcludePathsDir = Join-Path $BashDir "exclude-paths.txt"
if (Test-Path $ExcludePathsDir -PathType Container) {
    Remove-Item $ExcludePathsDir -Recurse -Force
    Write-Host "  ❌ Removed directory: exclude-paths.txt"
    $RemovedCount++
}

Write-Host "✅ Removed $RemovedCount unnecessary files" -ForegroundColor Green
Write-Host ""

# List remaining essential scripts
Write-Host "📋 Essential scripts remaining for 8-step security scan:" -ForegroundColor Blue
Write-Host ""

Write-Host "🎯 Core Orchestration:" -ForegroundColor Green
Write-Host "  • run-target-security-scan.ps1 - Main orchestration script"
Write-Host ""

Write-Host "🛡️  8 Security Layers:" -ForegroundColor Green
Write-Host "  • run-trufflehog-scan.ps1  - Layer 1: Secret Detection"
Write-Host "  • run-clamav-scan.ps1      - Layer 2: Malware Detection"
Write-Host "  • run-checkov-scan.ps1     - Layer 3: Infrastructure Security"
Write-Host "  • run-grype-scan.ps1       - Layer 4: Vulnerability Detection"
Write-Host "  • run-trivy-scan.ps1       - Layer 5: Container Security"
Write-Host "  • run-xeol-scan.ps1        - Layer 6: End-of-Life Detection"
Write-Host "  • run-sonar-analysis.ps1   - Layer 7: Code Quality Analysis"
Write-Host "  • run-helm-build.ps1       - Layer 8: Helm Chart Building"
Write-Host ""

Write-Host "📊 Analysis & Reporting:" -ForegroundColor Green
Write-Host "  • generate-critical-high-summary.ps1 - Critical/High findings summary"
Write-Host "  • consolidate-security-reports.ps1   - Report consolidation"
Write-Host ""

Write-Host "🔧 Clean Backup Versions:" -ForegroundColor Green
foreach ($Script in $CleanScripts) {
    $FilePath = Join-Path $BashDir $Script
    if (Test-Path $FilePath) {
        Write-Host "  • $Script - Backup version"
    }
}

Write-Host ""
Write-Host "📁 Current scripts directory structure:" -ForegroundColor Blue
$ScriptCount = (Get-ChildItem $BashDir -Filter "*.ps1" -ErrorAction SilentlyContinue).Count
Write-Host "  📄 $ScriptCount PowerShell scripts remaining"

Write-Host ""
Write-Host "✅ Script cleanup completed!" -ForegroundColor Green
Write-Host "💡 To run the 8-step security scan, use:" -ForegroundColor Yellow
Write-Host "   .\run-target-security-scan.ps1 <target_directory> [full|quick|images|analysis]"
Write-Host ""
Write-Host "📦 Backup location: $BackupDir" -ForegroundColor Blue

# Show final count
$FinalCount = $ScriptCount
$OriginalCount = $FinalCount + $RemovedCount
Write-Host "📊 Final count: $FinalCount scripts (down from $OriginalCount)" -ForegroundColor Green
