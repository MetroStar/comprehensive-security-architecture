<#
.SYNOPSIS
    Scan Directory Security Findings Summary Script
    
.DESCRIPTION
    Analyzes security scan results for CRITICAL, HIGH, MEDIUM, and LOW severity findings
    Works with the new scan directory architecture: scans/{SCAN_ID}/{tool}/
    
.PARAMETER ScanId
    The scan ID to analyze
    
.PARAMETER TargetDir
    The target directory that was scanned
    
.PARAMETER ProjectRoot
    The project root directory (defaults to 2 levels up from script directory)
    
.NOTES
    PowerShell version of generate-scan-findings-summary.sh
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$ScanId,
    
    [string]$TargetDir,
    
    [string]$ProjectRoot
)

# Set up paths
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $ProjectRoot) {
    $ProjectRoot = Split-Path (Split-Path $ScriptDir -Parent) -Parent
}

$ScanDir = Join-Path $ProjectRoot "scans\$ScanId"
$OutputFile = Join-Path $ScanDir "security-findings-summary.json"
$OutputHtml = Join-Path $ScanDir "security-findings-summary.html"

# Validate scan directory exists
if (-not (Test-Path $ScanDir)) {
    Write-Host "❌ Scan directory not found: $ScanDir" -ForegroundColor Red
    exit 1
}

Write-Host "🚨 Generating Security Findings Summary for Scan: $ScanId" -ForegroundColor Blue

# Initialize summary object
$Summary = @{
    summary = @{
        scan_id = $ScanId
        target_directory = $TargetDir
        scan_timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
        total_critical = 0
        total_high = 0
        total_medium = 0
        total_low = 0
        tools_analyzed = @()
        summary_by_tool = @{}
    }
    critical_findings = @()
    high_findings = @()
    medium_findings = @()
    low_findings = @()
}

$TotalCritical = 0
$TotalHigh = 0
$TotalMedium = 0
$TotalLow = 0
$ToolsAnalyzed = @()

# Process TruffleHog results
$TruffleHogDir = Join-Path $ScanDir "trufflehog"
if (Test-Path $TruffleHogDir) {
    $TruffleHogFiles = Get-ChildItem -Path $TruffleHogDir -Filter "*-results.json" -ErrorAction SilentlyContinue
    
    foreach ($File in $TruffleHogFiles) {
        $ToolsAnalyzed += "TruffleHog"
        
        # Read NDJSON format
        $Lines = Get-Content $File.FullName | Where-Object { $_ -and $_ -notmatch '"level":' }
        
        foreach ($Line in $Lines) {
            try {
                $Secret = $Line | ConvertFrom-Json
                
                # Critical: Verified secrets
                if ($Secret.Verified -eq $true) {
                    $Finding = @{
                        tool = "TruffleHog"
                        type = "verified_secret"
                        severity = "Critical"
                        detector = $Secret.DetectorName
                        file_path = $Secret.SourceMetadata.Data.Filesystem.file
                        line_number = $Secret.SourceMetadata.Data.Filesystem.line
                        description = "CRITICAL: VERIFIED $($Secret.DetectorName) credentials - IMMEDIATE ACTION REQUIRED"
                        credential_type = $Secret.DetectorName
                        verified = $Secret.Verified
                        scan_location = "scans/$ScanId/trufflehog/"
                        validation_steps = @(
                            "1. Check if credentials are still active"
                            "2. Rotate credentials immediately"
                            "3. Review access logs for unauthorized usage"
                            "4. Remove from code and Git history"
                        )
                        priority = "P0 - Critical"
                        impact = "Full database access with verified working credentials"
                    }
                    $Summary.critical_findings += $Finding
                    $TotalCritical++
                }
                # High: Private keys
                elseif ($Secret.DetectorName -eq "PrivateKey") {
                    $Finding = @{
                        tool = "TruffleHog"
                        type = "private_key"
                        severity = "High"
                        detector = $Secret.DetectorName
                        file_path = $Secret.SourceMetadata.Data.Filesystem.file
                        line_number = $Secret.SourceMetadata.Data.Filesystem.line
                        description = "HIGH: Private key detected"
                        verified = $Secret.Verified
                        scan_location = "scans/$ScanId/trufflehog/"
                        validation_steps = @(
                            "1. Identify key purpose and system access"
                            "2. Generate new key pair if still in use"
                            "3. Update systems with new public key"
                            "4. Remove private key from repository"
                            "5. Audit systems for unauthorized access"
                        )
                        priority = "P1 - High"
                        impact = "Potential unauthorized system access"
                    }
                    $Summary.high_findings += $Finding
                    $TotalHigh++
                }
                # Medium: Unverified database credentials
                elseif ($Secret.DetectorName -match "Postgres|MySQL|MongoDB" -and $Secret.Verified -eq $false) {
                    $Finding = @{
                        tool = "TruffleHog"
                        type = "database_credential"
                        severity = "Medium"
                        detector = $Secret.DetectorName
                        file_path = $Secret.SourceMetadata.Data.Filesystem.file
                        line_number = $Secret.SourceMetadata.Data.Filesystem.line
                        description = "MEDIUM: $($Secret.DetectorName) credentials found (unverified)"
                        verified = $Secret.Verified
                        scan_location = "scans/$ScanId/trufflehog/"
                        validation_steps = @(
                            "1. Test if credentials are valid"
                            "2. Check if database/service exists"
                            "3. Remove if test credentials"
                            "4. Rotate if production credentials"
                        )
                        priority = "P2 - Medium"
                        impact = "Potential database access if credentials are valid"
                    }
                    $Summary.medium_findings += $Finding
                    $TotalMedium++
                }
            }
            catch {
                # Skip invalid JSON lines
            }
        }
    }
}

# Process Grype results
$GrypeDir = Join-Path $ScanDir "grype"
if (Test-Path $GrypeDir) {
    $GrypeFiles = Get-ChildItem -Path $GrypeDir -Filter "*-results.json" -ErrorAction SilentlyContinue | 
                  Where-Object { $_.Name -notmatch "sbom" }
    
    foreach ($File in $GrypeFiles) {
        $ScanType = $File.Name -replace '.*grype-', '' -replace '-results.json', ''
        $ToolsAnalyzed += "Grype-$ScanType"
        
        try {
            $Content = Get-Content $File.FullName -Raw | ConvertFrom-Json
            
            foreach ($Match in $Content.matches) {
                $Severity = $Match.vulnerability.severity
                $FixAvailable = if ($Match.vulnerability.fix.versions) { "Yes" } else { "No" }
                $CvssScore = if ($Match.vulnerability.cvss -and $Match.vulnerability.cvss[0].metrics.baseScore) { 
                    $Match.vulnerability.cvss[0].metrics.baseScore 
                } else { 
                    "N/A" 
                }
                
                $Finding = @{
                    tool = "Grype-$ScanType"
                    type = "vulnerability"
                    severity = $Severity
                    vulnerability_id = $Match.vulnerability.id
                    package_name = $Match.artifact.name
                    package_version = $Match.artifact.version
                    package_type = $Match.artifact.type
                    description = $Match.vulnerability.description
                    cvss_score = $CvssScore
                    fix_available = $FixAvailable
                    fixed_versions = $Match.vulnerability.fix.versions
                    scan_location = "scans/$ScanId/grype/"
                    result_file = $File.Name
                }
                
                if ($Severity -eq "Critical") {
                    $Finding.validation_steps = @(
                        "1. Verify package is actually in use"
                        "2. Check if vulnerability affects your usage"
                        "3. Update to fixed version if available"
                        "4. Apply workarounds if no fix available"
                    )
                    $Finding.priority = "P0 - Critical"
                    $Finding.impact = "Critical vulnerability in dependency"
                    $Summary.critical_findings += $Finding
                    $TotalCritical++
                }
                elseif ($Severity -eq "High") {
                    $Finding.validation_steps = @(
                        "1. Verify package is actually in use"
                        "2. Check if vulnerability affects your usage"
                        "3. Update to fixed version if available"
                        "4. Consider alternative packages if no fix"
                    )
                    $Finding.priority = "P1 - High"
                    $Finding.impact = "High severity vulnerability in dependency"
                    $Summary.high_findings += $Finding
                    $TotalHigh++
                }
                elseif ($Severity -eq "Medium") {
                    $Summary.medium_findings += $Finding
                    $TotalMedium++
                }
                elseif ($Severity -eq "Low") {
                    $Summary.low_findings += $Finding
                    $TotalLow++
                }
            }
        }
        catch {
            Write-Host "  ⚠️ Error processing $($File.Name): $_" -ForegroundColor Yellow
        }
    }
}

# Process Trivy results
$TrivyDir = Join-Path $ScanDir "trivy"
if (Test-Path $TrivyDir) {
    $TrivyFiles = Get-ChildItem -Path $TrivyDir -Filter "*-results.json" -ErrorAction SilentlyContinue
    
    foreach ($File in $TrivyFiles) {
        $ScanType = $File.Name -replace '.*trivy-', '' -replace '-results.json', ''
        $ToolsAnalyzed += "Trivy-$ScanType"
        
        try {
            $Content = Get-Content $File.FullName -Raw | ConvertFrom-Json
            
            foreach ($Result in $Content.Results) {
                if ($Result.Vulnerabilities) {
                    foreach ($Vuln in $Result.Vulnerabilities) {
                        $CvssScore = if ($Vuln.CVSS.nvd.V3Score) { 
                            $Vuln.CVSS.nvd.V3Score 
                        } else { 
                            "N/A" 
                        }
                        $FixAvailable = if ($Vuln.FixedVersion) { "Yes" } else { "No" }
                        
                        $Finding = @{
                            tool = "Trivy-$ScanType"
                            type = "vulnerability"
                            severity = $Vuln.Severity
                            id = $Vuln.VulnerabilityID
                            package = $Vuln.PkgName
                            version = $Vuln.InstalledVersion
                            description = $Vuln.Description
                            cvss_score = $CvssScore
                            fix_available = $FixAvailable
                        }
                        
                        switch ($Vuln.Severity) {
                            "CRITICAL" {
                                $Summary.critical_findings += $Finding
                                $TotalCritical++
                            }
                            "HIGH" {
                                $Summary.high_findings += $Finding
                                $TotalHigh++
                            }
                            "MEDIUM" {
                                $Summary.medium_findings += $Finding
                                $TotalMedium++
                            }
                            "LOW" {
                                $Summary.low_findings += $Finding
                                $TotalLow++
                            }
                        }
                    }
                }
            }
        }
        catch {
            Write-Host "  ⚠️ Error processing $($File.Name): $_" -ForegroundColor Yellow
        }
    }
}

# Process Checkov results
$CheckovDir = Join-Path $ScanDir "checkov"
if (Test-Path $CheckovDir) {
    $CheckovFiles = Get-ChildItem -Path $CheckovDir -Filter "*-results.json" -ErrorAction SilentlyContinue
    
    foreach ($File in $CheckovFiles) {
        $ToolsAnalyzed += "Checkov"
        
        try {
            $Content = Get-Content $File.FullName -Raw | ConvertFrom-Json
            
            if ($Content.results.failed_checks) {
                foreach ($Check in $Content.results.failed_checks) {
                    $Severity = switch ($Check.severity) {
                        "CRITICAL" { "Critical" }
                        "HIGH" { "High" }
                        "MEDIUM" { "Medium" }
                        default { "Low" }
                    }
                    
                    $Finding = @{
                        tool = "Checkov"
                        type = "iac_misconfiguration"
                        severity = $Severity
                        id = $Check.check_id
                        description = $Check.check_name
                        file = $Check.file_path
                        line = $Check.file_line_range
                        guideline = $Check.guideline
                    }
                    
                    switch ($Severity) {
                        "Critical" {
                            $Summary.critical_findings += $Finding
                            $TotalCritical++
                        }
                        "High" {
                            $Summary.high_findings += $Finding
                            $TotalHigh++
                        }
                        "Medium" {
                            $Summary.medium_findings += $Finding
                            $TotalMedium++
                        }
                        "Low" {
                            $Summary.low_findings += $Finding
                            $TotalLow++
                        }
                    }
                }
            }
        }
        catch {
            Write-Host "  ⚠️ Error processing $($File.Name): $_" -ForegroundColor Yellow
        }
    }
}

# Update final summary
$Summary.summary.tools_analyzed = $ToolsAnalyzed | Select-Object -Unique
$Summary.summary.total_critical = $TotalCritical
$Summary.summary.total_high = $TotalHigh
$Summary.summary.total_medium = $TotalMedium
$Summary.summary.total_low = $TotalLow

# Save JSON report
$Summary | ConvertTo-Json -Depth 10 | Set-Content -Path $OutputFile -Encoding UTF8

Write-Host "✅ Security findings summary generated: $(Split-Path $OutputFile -Leaf)" -ForegroundColor Green
Write-Host "🔴 Critical: $TotalCritical" -ForegroundColor Red
Write-Host "🟡 High: $TotalHigh" -ForegroundColor Yellow
Write-Host "🔵 Medium: $TotalMedium" -ForegroundColor Blue
Write-Host "⚪ Low: $TotalLow" -ForegroundColor White
Write-Host "📊 Tools analyzed: $($ToolsAnalyzed.Count)" -ForegroundColor Blue
