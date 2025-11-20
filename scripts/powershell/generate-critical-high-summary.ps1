<#
.SYNOPSIS
    Critical and High Severity Findings Summary Script
    
.DESCRIPTION
    Analyzes all security scan results and extracts CRITICAL and HIGH severity findings
    Updated for comprehensive security architecture
    
.NOTES
    PowerShell version of generate-critical-high-summary.sh
#>

param(
    [string]$ReportsRoot
)

# Set up paths
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $ReportsRoot) {
    $ReportsRoot = Join-Path (Split-Path (Split-Path $ScriptDir -Parent) -Parent) "reports"
}
$OutputFile = Join-Path $ReportsRoot "security-reports\critical-high-findings-summary.json"
$OutputHtml = Join-Path $ReportsRoot "security-reports\critical-high-findings-summary.html"

# Create output directory
$null = New-Item -ItemType Directory -Force -Path (Split-Path $OutputFile -Parent)

Write-Host ""
Write-Host "============================================" -ForegroundColor White
Write-Host "🚨 Critical & High Severity Findings Summary" -ForegroundColor White
Write-Host "============================================" -ForegroundColor White
Write-Host ""

# Initialize summary object
$TargetName = Split-Path (Get-Location) -Leaf
$Username = $env:USERNAME
$Timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
$ScanId = "${TargetName}_${Username}_$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss')"

$Summary = @{
    summary = @{
        scan_timestamp = $Timestamp
        scan_id = $ScanId
        total_critical = 0
        total_high = 0
        tools_analyzed = @()
        summary_by_tool = @{}
    }
    critical_findings = @()
    high_findings = @()
}

$TotalCritical = 0
$TotalHigh = 0
$ToolsFound = @()

Write-Host "📊 Analyzing security scan results..." -ForegroundColor Blue
Write-Host ""

# Function to analyze Trivy results
function Analyze-Trivy {
    Write-Host "🔍 Analyzing Trivy (Container Security) results..." -ForegroundColor Blue
    $TrivyCritical = 0
    $TrivyHigh = 0
    $Findings = @()
    
    $TrivyFiles = Get-ChildItem -Path (Join-Path $ReportsRoot "trivy-reports") -Filter "trivy-*-results.json" -ErrorAction SilentlyContinue
    
    foreach ($File in $TrivyFiles) {
        Write-Host "  📄 Processing: $($File.Name)"
        
        try {
            $Content = Get-Content $File.FullName -Raw | ConvertFrom-Json
            
            # Extract CRITICAL vulnerabilities
            foreach ($Result in $Content.Results) {
                if ($Result.Vulnerabilities) {
                    foreach ($Vuln in $Result.Vulnerabilities) {
                        if ($Vuln.Severity -eq "CRITICAL") {
                            $Finding = "$($Vuln.VulnerabilityID): $($Vuln.Title) (Package: $($Vuln.PkgName))"
                            $Findings += @{
                                severity = "CRITICAL"
                                tool = "Trivy"
                                source = $File.Name
                                finding = $Finding
                            }
                            $TrivyCritical++
                        }
                        elseif ($Vuln.Severity -eq "HIGH") {
                            $Finding = "$($Vuln.VulnerabilityID): $($Vuln.Title) (Package: $($Vuln.PkgName))"
                            $Findings += @{
                                severity = "HIGH"
                                tool = "Trivy"
                                source = $File.Name
                                finding = $Finding
                            }
                            $TrivyHigh++
                        }
                    }
                }
            }
        }
        catch {
            Write-Host "  ⚠️ Error processing $($File.Name): $_" -ForegroundColor Yellow
        }
    }
    
    # Add findings to summary
    foreach ($Finding in $Findings) {
        if ($Finding.severity -eq "CRITICAL") {
            $Script:Summary.critical_findings += $Finding
        }
        else {
            $Script:Summary.high_findings += $Finding
        }
    }
    
    $Script:TotalCritical += $TrivyCritical
    $Script:TotalHigh += $TrivyHigh
    $Script:ToolsFound += "Trivy"
    
    # Update summary
    $Script:Summary.summary.summary_by_tool.Trivy = @{
        critical = $TrivyCritical
        high = $TrivyHigh
    }
    
    Write-Host "    🚨 Critical: $TrivyCritical, ⚠️  High: $TrivyHigh"
}

# Function to analyze Grype results
function Analyze-Grype {
    Write-Host "🔍 Analyzing Grype (Vulnerability Detection) results..." -ForegroundColor Blue
    $GrypeCritical = 0
    $GrypeHigh = 0
    $Findings = @()
    
    $GrypeFiles = Get-ChildItem -Path (Join-Path $ReportsRoot "grype-reports") -Filter "grype-*-results.json" -ErrorAction SilentlyContinue
    
    foreach ($File in $GrypeFiles) {
        Write-Host "  📄 Processing: $($File.Name)"
        
        try {
            $Content = Get-Content $File.FullName -Raw | ConvertFrom-Json
            
            # Extract vulnerabilities
            foreach ($Match in $Content.matches) {
                if ($Match.vulnerability.severity -eq "Critical") {
                    $Finding = "$($Match.vulnerability.id): $($Match.vulnerability.description) (Package: $($Match.artifact.name))"
                    $Findings += @{
                        severity = "CRITICAL"
                        tool = "Grype"
                        source = $File.Name
                        finding = $Finding
                    }
                    $GrypeCritical++
                }
                elseif ($Match.vulnerability.severity -eq "High") {
                    $Finding = "$($Match.vulnerability.id): $($Match.vulnerability.description) (Package: $($Match.artifact.name))"
                    $Findings += @{
                        severity = "HIGH"
                        tool = "Grype"
                        source = $File.Name
                        finding = $Finding
                    }
                    $GrypeHigh++
                }
            }
        }
        catch {
            Write-Host "  ⚠️ Error processing $($File.Name): $_" -ForegroundColor Yellow
        }
    }
    
    # Add findings to summary
    foreach ($Finding in $Findings) {
        if ($Finding.severity -eq "CRITICAL") {
            $Script:Summary.critical_findings += $Finding
        }
        else {
            $Script:Summary.high_findings += $Finding
        }
    }
    
    $Script:TotalCritical += $GrypeCritical
    $Script:TotalHigh += $GrypeHigh
    $Script:ToolsFound += "Grype"
    
    # Update summary
    $Script:Summary.summary.summary_by_tool.Grype = @{
        critical = $GrypeCritical
        high = $GrypeHigh
    }
    
    Write-Host "    🚨 Critical: $GrypeCritical, ⚠️  High: $GrypeHigh"
}

# Function to analyze TruffleHog results
function Analyze-TruffleHog {
    Write-Host "🔍 Analyzing TruffleHog (Secret Detection) results..." -ForegroundColor Blue
    $TruffleHogHigh = 0
    $Findings = @()
    
    $TruffleHogFiles = Get-ChildItem -Path (Join-Path $ReportsRoot "trufflehog-reports") -Filter "trufflehog-*-results.json" -ErrorAction SilentlyContinue
    
    foreach ($File in $TruffleHogFiles) {
        Write-Host "  📄 Processing: $($File.Name)"
        
        try {
            # TruffleHog uses NDJSON format - read line by line
            $Lines = Get-Content $File.FullName | Where-Object { $_ -and $_ -notmatch '"level":' }
            
            foreach ($Line in $Lines) {
                try {
                    $Secret = $Line | ConvertFrom-Json
                    
                    if ($Secret.Verified -eq $true) {
                        $FilePath = $Secret.SourceMetadata.Data.Filesystem.file
                        $Finding = "$($Secret.DetectorName): Verified secret found in $FilePath"
                        $Findings += @{
                            severity = "HIGH"
                            tool = "TruffleHog"
                            source = $File.Name
                            finding = $Finding
                        }
                        $TruffleHogHigh++
                    }
                    elseif ($Secret.Verified -eq $false) {
                        $FilePath = $Secret.SourceMetadata.Data.Filesystem.file
                        $Finding = "$($Secret.DetectorName): Potential secret found in $FilePath"
                        $Findings += @{
                            severity = "HIGH"
                            tool = "TruffleHog"
                            source = $File.Name
                            finding = $Finding
                        }
                        $TruffleHogHigh++
                    }
                }
                catch {
                    # Skip invalid JSON lines
                }
            }
        }
        catch {
            Write-Host "  ⚠️ Error processing $($File.Name): $_" -ForegroundColor Yellow
        }
    }
    
    # Add findings to summary
    foreach ($Finding in $Findings) {
        $Script:Summary.high_findings += $Finding
    }
    
    $Script:TotalHigh += $TruffleHogHigh
    $Script:ToolsFound += "TruffleHog"
    
    # Update summary
    $Script:Summary.summary.summary_by_tool.TruffleHog = @{
        critical = 0
        high = $TruffleHogHigh
    }
    
    Write-Host "    🚨 Critical: 0, ⚠️  High: $TruffleHogHigh"
}

# Function to analyze Checkov results
function Analyze-Checkov {
    Write-Host "🔍 Analyzing Checkov (Infrastructure Security) results..." -ForegroundColor Blue
    $CheckovCritical = 0
    $CheckovHigh = 0
    $Findings = @()
    
    $CheckovFiles = Get-ChildItem -Path (Join-Path $ReportsRoot "checkov-reports") -Filter "*results*.json" -ErrorAction SilentlyContinue
    
    foreach ($File in $CheckovFiles) {
        Write-Host "  📄 Processing: $($File.Name)"
        
        try {
            $Content = Get-Content $File.FullName -Raw | ConvertFrom-Json
            
            # Look for failed checks
            if ($Content.results.failed_checks) {
                foreach ($Check in $Content.results.failed_checks) {
                    if ($Check.severity -eq "CRITICAL") {
                        $Finding = "CRITICAL: $($Check.check_name) ($($Check.file_path))"
                        $Findings += @{
                            severity = "CRITICAL"
                            tool = "Checkov"
                            source = $File.Name
                            finding = $Finding
                        }
                        $CheckovCritical++
                    }
                    elseif ($Check.severity -eq "HIGH") {
                        $Finding = "HIGH: $($Check.check_name) ($($Check.file_path))"
                        $Findings += @{
                            severity = "HIGH"
                            tool = "Checkov"
                            source = $File.Name
                            finding = $Finding
                        }
                        $CheckovHigh++
                    }
                }
            }
        }
        catch {
            Write-Host "  ⚠️ Error processing $($File.Name): $_" -ForegroundColor Yellow
        }
    }
    
    # Add findings to summary
    foreach ($Finding in $Findings) {
        if ($Finding.severity -eq "CRITICAL") {
            $Script:Summary.critical_findings += $Finding
        }
        else {
            $Script:Summary.high_findings += $Finding
        }
    }
    
    $Script:TotalCritical += $CheckovCritical
    $Script:TotalHigh += $CheckovHigh
    $Script:ToolsFound += "Checkov"
    
    # Update summary
    $Script:Summary.summary.summary_by_tool.Checkov = @{
        critical = $CheckovCritical
        high = $CheckovHigh
    }
    
    Write-Host "    🚨 Critical: $CheckovCritical, ⚠️  High: $CheckovHigh"
}

# Run analysis for each tool
if (Test-Path (Join-Path $ReportsRoot "trivy-reports")) {
    Analyze-Trivy
}

if (Test-Path (Join-Path $ReportsRoot "grype-reports")) {
    Analyze-Grype
}

if (Test-Path (Join-Path $ReportsRoot "trufflehog-reports")) {
    Analyze-TruffleHog
}

if (Test-Path (Join-Path $ReportsRoot "checkov-reports")) {
    Analyze-Checkov
}

# Update final totals
$Summary.summary.total_critical = $TotalCritical
$Summary.summary.total_high = $TotalHigh
$Summary.summary.tools_analyzed = $ToolsFound

# Save JSON report
$Summary | ConvertTo-Json -Depth 10 | Set-Content -Path $OutputFile -Encoding UTF8

# Generate HTML report
$HtmlContent = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Critical & High Severity Findings Summary</title>
    <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 20px; background-color: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .header { text-align: center; margin-bottom: 30px; }
        .summary-cards { display: flex; gap: 20px; margin-bottom: 30px; flex-wrap: wrap; }
        .card { flex: 1; min-width: 200px; padding: 20px; border-radius: 8px; text-align: center; }
        .critical-card { background: linear-gradient(135deg, #ff6b6b, #ee5a52); color: white; }
        .high-card { background: linear-gradient(135deg, #ffa726, #ff9800); color: white; }
        .info-card { background: linear-gradient(135deg, #42a5f5, #2196f3); color: white; }
        .card h3 { margin: 0 0 10px 0; font-size: 18px; }
        .card .number { font-size: 36px; font-weight: bold; margin: 10px 0; }
        .findings-section { margin: 30px 0; }
        .findings-section h2 { color: #333; border-bottom: 2px solid #ddd; padding-bottom: 10px; }
        .finding-item { background: #f9f9f9; margin: 10px 0; padding: 15px; border-radius: 5px; border-left: 4px solid #ddd; }
        .finding-item.critical { border-left-color: #ff6b6b; }
        .finding-item.high { border-left-color: #ffa726; }
        .tool-badge { display: inline-block; background: #e3f2fd; color: #1976d2; padding: 4px 8px; border-radius: 4px; font-size: 12px; margin-right: 10px; }
        .severity-badge { display: inline-block; padding: 4px 8px; border-radius: 4px; font-size: 12px; font-weight: bold; margin-right: 10px; }
        .severity-badge.critical { background: #ff6b6b; color: white; }
        .severity-badge.high { background: #ffa726; color: white; }
        .timestamp { text-align: center; color: #666; margin-top: 30px; font-size: 14px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🚨 Critical & High Severity Findings Summary</h1>
            <p>Comprehensive Security Architecture Analysis</p>
        </div>
        
        <div class="summary-cards">
            <div class="card critical-card">
                <h3>Critical Findings</h3>
                <div class="number">$TotalCritical</div>
                <p>Immediate attention required</p>
            </div>
            <div class="card high-card">
                <h3>High Findings</h3>
                <div class="number">$TotalHigh</div>
                <p>Should be addressed soon</p>
            </div>
            <div class="card info-card">
                <h3>Tools Analyzed</h3>
                <div class="number">$($ToolsFound.Count)</div>
                <p>Security scanners</p>
            </div>
        </div>
        
        <div class="findings-section">
            <h2>🔥 Critical Findings (Immediate Action Required)</h2>
            <div id="critical-findings"></div>
        </div>
        
        <div class="findings-section">
            <h2>⚠️ High Severity Findings (High Priority)</h2>
            <div id="high-findings"></div>
        </div>
        
        <div class="timestamp">
            Report generated: $Timestamp
        </div>
    </div>
    
    <script>
        // Load findings from JSON and populate HTML
        fetch('critical-high-findings-summary.json')
            .then(response => response.json())
            .then(data => {
                const criticalDiv = document.getElementById('critical-findings');
                const highDiv = document.getElementById('high-findings');
                
                if (data.critical_findings.length === 0) {
                    criticalDiv.innerHTML = '<p style="color: #4caf50; font-style: italic;">✅ No critical findings detected!</p>';
                } else {
                    data.critical_findings.forEach(finding => {
                        const div = document.createElement('div');
                        div.className = 'finding-item critical';
                        div.innerHTML = `
                            <span class="severity-badge critical">CRITICAL</span>
                            <span class="tool-badge">`+finding.tool+`</span>
                            <strong>`+finding.finding+`</strong>
                            <br><small>Source: `+finding.source+`</small>
                        `;
                        criticalDiv.appendChild(div);
                    });
                }
                
                if (data.high_findings.length === 0) {
                    highDiv.innerHTML = '<p style="color: #4caf50; font-style: italic;">✅ No high severity findings detected!</p>';
                } else {
                    data.high_findings.forEach(finding => {
                        const div = document.createElement('div');
                        div.className = 'finding-item high';
                        div.innerHTML = `
                            <span class="severity-badge high">HIGH</span>
                            <span class="tool-badge">`+finding.tool+`</span>
                            <strong>`+finding.finding+`</strong>
                            <br><small>Source: `+finding.source+`</small>
                        `;
                        highDiv.appendChild(div);
                    });
                }
            })
            .catch(error => {
                console.error('Error loading findings:', error);
                document.getElementById('critical-findings').innerHTML = '<p style="color: red;">Error loading critical findings data</p>';
                document.getElementById('high-findings').innerHTML = '<p style="color: red;">Error loading high findings data</p>';
            });
    </script>
</body>
</html>
"@

$HtmlContent | Set-Content -Path $OutputHtml -Encoding UTF8

Write-Host ""
Write-Host "============================================" -ForegroundColor White
Write-Host "📊 CRITICAL & HIGH SEVERITY SUMMARY" -ForegroundColor White
Write-Host "============================================" -ForegroundColor White
Write-Host ""
Write-Host "🚨 CRITICAL FINDINGS: $TotalCritical" -ForegroundColor Red
Write-Host "⚠️  HIGH SEVERITY FINDINGS: $TotalHigh" -ForegroundColor Yellow
Write-Host ""
Write-Host "🔧 Tools Analyzed: $($ToolsFound -join ', ')" -ForegroundColor Blue
Write-Host ""
Write-Host "📁 Reports Generated:" -ForegroundColor Blue
Write-Host "📄 JSON Report: $OutputFile"
Write-Host "🌐 HTML Report: $OutputHtml"
Write-Host ""
Write-Host "============================================" -ForegroundColor White

if ($TotalCritical -gt 0) {
    Write-Host "⚠️  CRITICAL ISSUES FOUND - IMMEDIATE ACTION REQUIRED!" -ForegroundColor Red
}
elseif ($TotalHigh -gt 0) {
    Write-Host "⚠️  HIGH SEVERITY ISSUES FOUND - SHOULD BE ADDRESSED" -ForegroundColor Yellow
}
else {
    Write-Host "✅ No critical or high severity issues found!" -ForegroundColor Green
}

Write-Host "============================================" -ForegroundColor White
