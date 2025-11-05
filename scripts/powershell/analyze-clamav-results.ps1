# ClamAV Results Analysis Script
# Analyzes ClamAV scan results and provides detailed reporting

$ScanLog = ".\clamav-reports\clamav-scan.log"
$InfectedLog = ".\clamav-reports\clamav-infected.log"

Write-Host "============================================"
Write-Host "ClamAV Scan Results Analysis"
Write-Host "============================================"
Write-Host ""

# Check if scan log exists
if (-not (Test-Path $ScanLog)) {
    Write-Host "❌ No scan log found at $ScanLog" -ForegroundColor Red
    Write-Host "Run '.\run-clamav-scan.ps1' first to generate results."
    exit 1
}

Write-Host "📊 Scan Overview:"
Write-Host "=================="

# Extract key metrics from the scan summary
$LogContent = Get-Content $ScanLog -Raw

if ($LogContent -match "SCAN SUMMARY") {
    $KnownViruses = if ($LogContent -match "Known viruses:\s+(\d+)") { $Matches[1] } else { "Unknown" }
    $EngineVersion = if ($LogContent -match "Engine version:\s+([\d\.]+)") { $Matches[1] } else { "Unknown" }
    $ScannedDirs = if ($LogContent -match "Scanned directories:\s+(\d+)") { $Matches[1] } else { "Unknown" }
    $ScannedFiles = if ($LogContent -match "Scanned files:\s+(\d+)") { $Matches[1] } else { "Unknown" }
    $InfectedFiles = if ($LogContent -match "Infected files:\s+(\d+)") { $Matches[1] } else { "0" }
    $DataScanned = if ($LogContent -match "Data scanned:\s+([\d\.]+ \w+)") { $Matches[1] } else { "Unknown" }
    $ScanTime = if ($LogContent -match "Time:\s+(.+)") { $Matches[1] } else { "Unknown" }
    
    Write-Host "ClamAV Engine Version: $EngineVersion"
    Write-Host "Known Virus Signatures: $KnownViruses"
    Write-Host "Directories Scanned: $ScannedDirs"
    Write-Host "Files Scanned: $ScannedFiles"
    Write-Host "Data Scanned: $DataScanned"
    Write-Host "Scan Duration: $ScanTime"
    Write-Host ""
    
    # Security status
    if ([int]$InfectedFiles -eq 0) {
        Write-Host "🎉 Security Status: CLEAN" -ForegroundColor Green
        Write-Host "✅ No malware or viruses detected" -ForegroundColor Green
    } else {
        Write-Host "🚨 Security Status: THREATS DETECTED" -ForegroundColor Red
        Write-Host "⚠️  Infected Files Found: $InfectedFiles" -ForegroundColor Yellow
    }
} else {
    Write-Host "⚠️  Unable to parse scan summary from log file" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "📁 Scan Coverage Analysis:"
Write-Host "=========================="

# Analyze what types of files were scanned
Write-Host "File types scanned:"
if (Test-Path $ScanLog) {
    $OkFiles = Select-String -Path $ScanLog -Pattern ": OK$" -AllMatches
    
    if ($OkFiles) {
        $Extensions = $OkFiles | ForEach-Object {
            if ($_.Line -match '\.([^.]+): OK$') {
                $Matches[1]
            }
        } | Group-Object | Sort-Object Count -Descending | Select-Object -First 10
        
        foreach ($ext in $Extensions) {
            Write-Host "  $($ext.Count) .$($ext.Name) files"
        }
    } else {
        Write-Host "  (File type breakdown not available - use verbose scanning for details)"
    }
}

Write-Host ""
Write-Host "🔍 Threat Analysis:"
Write-Host "==================="

if ((Test-Path $InfectedLog) -and ((Get-Item $InfectedLog).Length -gt 0)) {
    Write-Host "⚠️  INFECTED FILES DETECTED:" -ForegroundColor Red
    Write-Host "----------------------------"
    Get-Content $InfectedLog
    
    Write-Host ""
    Write-Host "🛡️  Recommended Actions:" -ForegroundColor Yellow
    Write-Host "- Quarantine or delete infected files immediately"
    Write-Host "- Run a full system scan"
    Write-Host "- Update antivirus definitions"
    Write-Host "- Check file sources and download history"
    Write-Host "- Consider scanning backup systems"
} else {
    Write-Host "✅ No threats detected in this scan" -ForegroundColor Green
    Write-Host ""
    Write-Host "🛡️  Security Recommendations:" -ForegroundColor Cyan
    Write-Host "- Continue regular scanning schedule"
    Write-Host "- Keep ClamAV definitions updated"
    Write-Host "- Monitor file uploads and downloads"
    Write-Host "- Maintain security best practices"
}

Write-Host ""
Write-Host "📈 Scan Performance:"
Write-Host "===================="

if (Test-Path $ScanLog) {
    $FileSize = (Get-Item $ScanLog).Length
    Write-Host "Log file size: $([math]::Round($FileSize/1KB, 2)) KB"
    Write-Host "Log location: $ScanLog"
}

Write-Host ""
Write-Host "📊 Summary Statistics:"
Write-Host "======================"

if (Test-Path $ScanLog) {
    $TotalLines = (Get-Content $ScanLog).Count
    $OkCount = (Select-String -Path $ScanLog -Pattern ": OK$" -AllMatches).Matches.Count
    $FoundCount = (Select-String -Path $ScanLog -Pattern "FOUND" -AllMatches).Matches.Count
    
    Write-Host "Total log lines: $TotalLines"
    Write-Host "Clean files: $OkCount"
    Write-Host "Threats found: $FoundCount"
}

Write-Host ""
Write-Host "============================================"
Write-Host "Analysis Complete"
Write-Host "============================================"
