<#
.SYNOPSIS
    Test script to verify timestamp consistency across all security tools
    
.DESCRIPTION
    Tests that all security scan tools use the same SCAN_ID and timestamp
    when running as part of the comprehensive security scan
    
.PARAMETER TargetDir
    Target directory to test (defaults to a temp directory)
    
.NOTES
    PowerShell version of test-scan-consistency.sh
#>

param(
    [string]$TargetDir
)

# Set up test environment
if (-not $TargetDir) {
    $TargetDir = Join-Path $env:TEMP "test-scan-consistency"
}

if (-not (Test-Path $TargetDir)) {
    $null = New-Item -ItemType Directory -Path $TargetDir -Force
}

# Create a test package.json
@{
    name = "test-project"
    version = "1.0.0"
} | ConvertTo-Json | Set-Content -Path (Join-Path $TargetDir "package.json")

Write-Host ""
Write-Host "============================================" -ForegroundColor White
Write-Host "🧪 Testing Scan ID Consistency" -ForegroundColor White
Write-Host "============================================" -ForegroundColor White
Write-Host ""

# Get script directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path (Split-Path $ScriptDir -Parent) -Parent

# Generate a single scan ID that should be used by all tools
$TargetName = Split-Path $TargetDir -Leaf
$Username = $env:USERNAME
$Timestamp = Get-Date -Format 'yyyy-MM-dd_HH-mm-ss'
$ScanId = "${TargetName}_${Username}_${Timestamp}"

Write-Host "🎯 Master Scan ID: $ScanId" -ForegroundColor Blue
Write-Host "📅 Master Timestamp: $Timestamp" -ForegroundColor Blue
Write-Host ""

# Export the scan ID
$env:SCAN_ID = $ScanId
$env:TARGET_DIR = $TargetDir

Write-Host "🔍 Testing individual tools with centralized SCAN_ID..." -ForegroundColor Yellow
Write-Host ""

# Test SBOM scan
Write-Host "✅ Testing SBOM scan..." -ForegroundColor Green
$SbomScript = Join-Path $ScriptDir "run-sbom-scan.ps1"
if (Test-Path $SbomScript) {
    & $SbomScript -TargetDir $TargetDir *>$null
    
    $SbomFile = Join-Path $RepoRoot "reports\sbom-reports\${ScanId}_sbom-summary.json"
    if (Test-Path $SbomFile) {
        Write-Host "  📄 SBOM file created with correct SCAN_ID: ${ScanId}_sbom-summary.json"
    }
    else {
        Write-Host "  ❌ SBOM file NOT found with expected SCAN_ID"
    }
}

# Test quick security scan
Write-Host ""
Write-Host "✅ Testing quick security scan..." -ForegroundColor Green
$TargetScanScript = Join-Path $ScriptDir "run-target-security-scan.ps1"
if (Test-Path $TargetScanScript) {
    & $TargetScanScript -TargetDir $TargetDir -Mode quick *>$null
}

Write-Host ""
Write-Host "📊 Checking file consistency..." -ForegroundColor Blue

# Find all files with the master scan ID
$FilesWithScanId = Get-ChildItem -Path (Join-Path $RepoRoot "reports") -Recurse -Filter "*${ScanId}*" -File -ErrorAction SilentlyContinue

if ($FilesWithScanId) {
    Write-Host "✅ Files found with consistent SCAN_ID:" -ForegroundColor Green
    foreach ($File in $FilesWithScanId) {
        $DirName = Split-Path (Split-Path $File.FullName -Parent) -Leaf
        Write-Host "  📄 $DirName\$($File.Name)"
    }
    
    # Count unique SCAN_IDs in generated files
    $AllScanFiles = Get-ChildItem -Path (Join-Path $RepoRoot "reports") -Recurse -Filter "*${TargetName}_${Username}_*" -File -ErrorAction SilentlyContinue
    
    $UniqueTimestamps = $AllScanFiles | ForEach-Object {
        if ($_.Name -match "${TargetName}_${Username}_(\d{4}-\d{2}-\d{2}_\d{2}-\d{2}-\d{2})") {
            $Matches[1]
        }
    } | Select-Object -Unique
    
    Write-Host ""
    if ($UniqueTimestamps.Count -eq 1) {
        Write-Host "✅ SUCCESS: All files use the same timestamp ($($UniqueTimestamps.Count) unique timestamp)" -ForegroundColor Green
    }
    else {
        Write-Host "⚠️  WARNING: Found $($UniqueTimestamps.Count) different timestamps" -ForegroundColor Yellow
        Write-Host "   This indicates timestamp inconsistency between tools" -ForegroundColor Yellow
        
        # Show the different timestamps
        Write-Host "🕐 Different timestamps found:" -ForegroundColor Blue
        foreach ($Ts in $UniqueTimestamps) {
            Write-Host "  📅 $Ts"
        }
    }
}
else {
    Write-Host "⚠️  No files found with the expected SCAN_ID" -ForegroundColor Yellow
}

# Cleanup test directory
Remove-Item -Path $TargetDir -Recurse -Force -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "============================================" -ForegroundColor White
Write-Host "🧪 Test Complete" -ForegroundColor White
Write-Host "============================================" -ForegroundColor White
