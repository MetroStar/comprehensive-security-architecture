<#
.SYNOPSIS
    Quick Scan Rollup Script
    
.DESCRIPTION
    Gets comprehensive summary of a specific scan ID
    
.PARAMETER ScanId
    The scan ID to get rollup for
    
.PARAMETER BaseRoot
    Base root directory (defaults to project root)
    
.NOTES
    PowerShell version of get-scan-rollup.sh
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$ScanId,
    
    [string]$BaseRoot
)

# Set up paths
if (-not $BaseRoot) {
    $ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    $BaseRoot = Split-Path (Split-Path $ScriptDir -Parent) -Parent
}

$ReportsRoot = Join-Path $BaseRoot "reports"
$ScansRoot = Join-Path $BaseRoot "scans"
$ScanDir = Join-Path $ScansRoot $ScanId

Write-Host ""
Write-Host "============================================" -ForegroundColor White
Write-Host "📊 Scan Rollup for: $ScanId" -ForegroundColor White
Write-Host "============================================" -ForegroundColor White
Write-Host ""

# Check if security findings summary exists
$SummaryFile = Join-Path $ReportsRoot "security-reports\${ScanId}_security-findings-summary.json"
if (Test-Path $SummaryFile) {
    Write-Host "✅ Security Findings Summary Found" -ForegroundColor Green
    Write-Host "📄 File: $SummaryFile"
    Write-Host ""
    
    try {
        $Summary = Get-Content $SummaryFile -Raw | ConvertFrom-Json
        
        # Extract key metrics
        $Critical = $Summary.summary.total_critical
        $High = $Summary.summary.total_high
        $Medium = $Summary.summary.total_medium
        $Low = $Summary.summary.total_low
        $Tools = $Summary.summary.tools_analyzed.Count
        
        Write-Host "📈 Security Findings Overview:" -ForegroundColor Cyan
        Write-Host "  🔴 Critical: $Critical" -ForegroundColor Red
        Write-Host "  🟡 High: $High" -ForegroundColor Yellow
        Write-Host "  🔵 Medium: $Medium" -ForegroundColor Blue
        Write-Host "  ⚪ Low: $Low" -ForegroundColor White
        Write-Host "  🔧 Tools: $Tools" -ForegroundColor Magenta
        Write-Host ""
        
        # Show tools analyzed
        Write-Host "🛠️  Tools Analyzed:" -ForegroundColor Cyan
        foreach ($Tool in $Summary.summary.tools_analyzed) {
            Write-Host "  • $Tool"
        }
        Write-Host ""
    }
    catch {
        Write-Host "⚠️  Error reading summary file: $_" -ForegroundColor Yellow
    }
}
else {
    Write-Host "⚠️  Security findings summary not found" -ForegroundColor Yellow
    Write-Host "📄 Expected: $SummaryFile"
    Write-Host ""
    
    # Try to generate it
    Write-Host "🔄 Attempting to generate summary..." -ForegroundColor Blue
    $GenerateScript = Join-Path (Split-Path $MyInvocation.MyCommand.Path -Parent) "generate-scan-findings-summary.ps1"
    if (Test-Path $GenerateScript) {
        $TargetName = $ScanId -replace '_.*$', ''
        & $GenerateScript -ScanId $ScanId -TargetDir $TargetName -ProjectRoot $BaseRoot
    }
}

# Check if scan directory exists
if (Test-Path $ScanDir) {
    Write-Host "✅ Scan Directory Found: $ScanDir" -ForegroundColor Green
    Write-Host ""
    
    # List all files in scan directory
    Write-Host "📁 Scan Directory Contents:" -ForegroundColor Cyan
    Get-ChildItem -Path $ScanDir -Recurse -File | Sort-Object FullName | ForEach-Object {
        $Size = "{0:N2}" -f ($_.Length / 1KB)
        $RelPath = $_.FullName.Replace("$ScanDir\", "")
        Write-Host "  📄 $RelPath ($Size KB)"
    }
}
else {
    Write-Host "⚠️  Scan directory not found: $ScanDir" -ForegroundColor Yellow
    Write-Host "🔍 Checking legacy reports structure..." -ForegroundColor Blue
    
    # List all files for this scan ID in reports
    Get-ChildItem -Path $ReportsRoot -Recurse -Filter "*${ScanId}*" -File -ErrorAction SilentlyContinue | 
        Sort-Object FullName | ForEach-Object {
        $Size = "{0:N2}" -f ($_.Length / 1KB)
        $ToolDir = Split-Path (Split-Path $_.FullName -Parent) -Leaf
        Write-Host "  📄 $ToolDir\$($_.Name) ($Size KB)"
    }
}

Write-Host ""

# Show individual tool summaries
Write-Host "🔍 Individual Tool Results:" -ForegroundColor Cyan

# Grype
$GrypeFiles = Get-ChildItem -Path (Join-Path $ReportsRoot "grype-reports") -Filter "${ScanId}_grype-*-results.json" -ErrorAction SilentlyContinue
if ($GrypeFiles) {
    Write-Host "  🎯 Grype Vulnerability Scanning:" -ForegroundColor Magenta
    foreach ($File in $GrypeFiles) {
        $ScanType = $File.Name -replace "${ScanId}_grype-", "" -replace "-results.json", ""
        try {
            $Content = Get-Content $File.FullName -Raw | ConvertFrom-Json
            $VulnCount = if ($Content.matches) { $Content.matches.Count } else { 0 }
            Write-Host "    • $ScanType`: $VulnCount vulnerabilities"
        }
        catch {
            Write-Host "    • $ScanType`: Error reading file"
        }
    }
}

# Trivy
$TrivyFiles = Get-ChildItem -Path (Join-Path $ReportsRoot "trivy-reports") -Filter "${ScanId}_trivy-*-results.json" -ErrorAction SilentlyContinue
if ($TrivyFiles) {
    Write-Host "  🛡️  Trivy Security Analysis:" -ForegroundColor Blue
    foreach ($File in $TrivyFiles) {
        $ScanType = $File.Name -replace "${ScanId}_trivy-", "" -replace "-results.json", ""
        try {
            $Content = Get-Content $File.FullName -Raw | ConvertFrom-Json
            $VulnCount = 0
            foreach ($Result in $Content.Results) {
                if ($Result.Vulnerabilities) {
                    $VulnCount += $Result.Vulnerabilities.Count
                }
            }
            Write-Host "    • $ScanType`: $VulnCount issues"
        }
        catch {
            Write-Host "    • $ScanType`: Error reading file"
        }
    }
}

# TruffleHog
$TruffleHogFiles = Get-ChildItem -Path (Join-Path $ReportsRoot "trufflehog-reports") -Filter "${ScanId}_trufflehog-*-results.json" -ErrorAction SilentlyContinue
if ($TruffleHogFiles) {
    Write-Host "  🔐 TruffleHog Secret Detection:" -ForegroundColor Red
    foreach ($File in $TruffleHogFiles) {
        $ScanType = $File.Name -replace "${ScanId}_trufflehog-", "" -replace "-results.json", ""
        try {
            $Lines = Get-Content $File.FullName | Where-Object { $_ -and $_ -notmatch '"level":' }
            $SecretCount = $Lines.Count
            Write-Host "    • $ScanType`: $SecretCount secrets"
        }
        catch {
            Write-Host "    • $ScanType`: Error reading file"
        }
    }
}

# Checkov
$CheckovFile = Join-Path $ReportsRoot "checkov-reports\${ScanId}_checkov-results.json"
if (Test-Path $CheckovFile) {
    Write-Host "  ☸️  Checkov Infrastructure Security:" -ForegroundColor Green
    try {
        $Content = Get-Content $CheckovFile -Raw | ConvertFrom-Json
        $FailedCount = if ($Content.results.failed_checks) { $Content.results.failed_checks.Count } else { 0 }
        $PassedCount = if ($Content.results.passed_checks) { $Content.results.passed_checks.Count } else { 0 }
        Write-Host "    • Failed: $FailedCount, Passed: $PassedCount"
    }
    catch {
        Write-Host "    • Error reading file"
    }
}

# SBOM
$SbomFiles = Get-ChildItem -Path (Join-Path $ReportsRoot "sbom-reports") -Filter "${ScanId}_sbom-*.json" -ErrorAction SilentlyContinue | 
             Where-Object { $_.Name -notmatch "summary" }
if ($SbomFiles) {
    Write-Host "  📋 SBOM Generation:" -ForegroundColor Cyan
    foreach ($File in $SbomFiles) {
        $ScanType = $File.Name -replace "${ScanId}_sbom-", "" -replace ".json", ""
        try {
            $Content = Get-Content $File.FullName -Raw | ConvertFrom-Json
            $ArtifactCount = if ($Content.artifacts) { $Content.artifacts.Count } else { 0 }
            Write-Host "    • $ScanType`: $ArtifactCount artifacts"
        }
        catch {
            Write-Host "    • $ScanType`: Error reading file"
        }
    }
}

# Xeol
$XeolFile = Join-Path $ReportsRoot "xeol-reports\${ScanId}_xeol-results.json"
if (Test-Path $XeolFile) {
    Write-Host "  ⏰ Xeol EOL Detection:" -ForegroundColor Yellow
    try {
        $Content = Get-Content $XeolFile -Raw | ConvertFrom-Json
        $EolCount = 0
        foreach ($Match in $Content.matches) {
            if ($Match.eol -eq $true) {
                $EolCount++
            }
        }
        Write-Host "    • EOL components: $EolCount"
    }
    catch {
        Write-Host "    • Error reading file"
    }
}

Write-Host ""
Write-Host "============================================" -ForegroundColor White
Write-Host "✅ Scan Rollup Complete" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor White
