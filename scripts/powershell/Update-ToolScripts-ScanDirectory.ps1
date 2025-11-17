# PowerShell Tool Scripts - Scan Directory Update Script
# Automatically updates all PowerShell tool scripts to use scan directory template

$ErrorActionPreference = "Stop"

$ScriptRoot = Split-Path -Parent $PSCommandPath
$ToolScripts = @(
    "run-checkov-scan.ps1",
    "run-clamav-scan.ps1",
    "run-grype-scan.ps1",
    "run-helm-build.ps1",
    "run-sonar-analysis.ps1",
    "run-trivy-scan.ps1",
    "run-trufflehog-scan.ps1",
    "run-xeol-scan.ps1"
)

Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host "PowerShell Tool Scripts - Scan Directory Template Update" -ForegroundColor Cyan
Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host ""

foreach ($script in $ToolScripts) {
    $scriptPath = Join-Path $ScriptRoot $script
    
    if (-not (Test-Path $scriptPath)) {
        Write-Host "⚠️  Skipping $script - File not found" -ForegroundColor Yellow
        continue
    }
    
    Write-Host "📝 Processing: $script" -ForegroundColor White
    
    # Read current content
    $content = Get-Content $scriptPath -Raw
    
    # Backup original
    $backupPath = "$scriptPath.backup"
    Copy-Item $scriptPath $backupPath -Force
    Write-Host "   ✅ Backup created: $script.backup" -ForegroundColor Green
    
    # Extract tool name from filename
    $toolName = $script -replace 'run-(.+)-(scan|build|analysis)\.ps1', '$1'
    
    # Check if already updated
    if ($content -match 'Scan-Directory-Template\.ps1') {
        Write-Host "   ℹ️  Already uses scan directory template - skipping" -ForegroundColor Cyan
        Remove-Item $backupPath -Force
        continue
    }
    
    # Find the param block end
    $paramBlockEnd = if ($content -match '(?s)\)\s*\n') {
        $Matches[0]
    } else {
        "`n"
    }
    
    # Build the template import section
    $templateImport = @"

# Initialize scan environment using scan directory approach
`$ScriptDir = Split-Path -Parent `$MyInvocation.MyCommand.Path

# Source the scan directory template
. "`$ScriptDir\Scan-Directory-Template.ps1"

# Initialize scan environment for $toolName
`$scanEnv = Initialize-ScanEnvironment -ToolName "$toolName"

# Extract scan information
if (`$env:SCAN_ID) {
    `$parts = `$env:SCAN_ID -split '_'
    `$TARGET_NAME = `$parts[0]
    `$USERNAME = `$parts[1]
    `$TIMESTAMP = `$parts[2..(`$parts.Length-1)] -join '_'
    `$SCAN_ID = `$env:SCAN_ID
}
else {
    `$targetPath = if (`$env:TARGET_DIR) { `$env:TARGET_DIR } else { Get-Location }
    `$TARGET_NAME = Split-Path -Leaf `$targetPath
    `$USERNAME = if (`$env:USERNAME) { `$env:USERNAME } else { `$env:USER }
    `$TIMESTAMP = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    `$SCAN_ID = "`${TARGET_NAME}_`${USERNAME}_`${TIMESTAMP}"
}

"@
    
    # Replace hardcoded output directory patterns
    $content = $content -replace '\$OutputDir\s*=\s*"[^"]*"', '# $OUTPUT_DIR set by Initialize-ScanEnvironment'
    $content = $content -replace '\$ScanLog\s*=\s*Join-Path[^\n]+', '# $SCAN_LOG set by Initialize-ScanEnvironment'
    $content = $content -replace 'New-Item -ItemType Directory -Force -Path \$OutputDir[^\n]+', '# Output directory created by template'
    
    # Replace references to $OutputDir with $OUTPUT_DIR (use global from template)
    $content = $content -replace '\$OutputDir\b', '$OUTPUT_DIR'
    $content = $content -replace '\$ScanLog\b', '$SCAN_LOG'
    
    # Insert template import after param block or at start
    if ($content -match '\)\s*\n\n') {
        $content = $content -replace '(\)\s*\n)\n', "`$1$templateImport"
    } elseif ($content -match '^# [^\n]+\n# [^\n]+') {
        # After comment header
        $content = $content -replace '(^# [^\n]+\n# [^\n]+\n)', "`$1$templateImport"
    } else {
        $content = $templateImport + $content
    }
    
    # Add Complete-ScanResults call at the end (before exit)
    if ($content -notmatch 'Complete-ScanResults') {
        $content = $content -replace '(exit 0)', "Complete-ScanResults -ToolName `"$toolName`"`n`$1"
    }
    
    # Write updated content
    Set-Content -Path $scriptPath -Value $content -NoNewline
    
    Write-Host "   ✅ Updated successfully" -ForegroundColor Green
    Write-Host ""
}

Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host "✅ Update Complete!" -ForegroundColor Green
Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:"
Write-Host "1. Review updated scripts for any syntax issues"
Write-Host "2. Test each script individually"
Write-Host "3. Update orchestrator (run-target-security-scan.ps1)"
Write-Host "4. Remove .backup files when confirmed working"
Write-Host ""
