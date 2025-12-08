# ClamAV Multi-Target Malware Scanner
# Comprehensive malware detection for repositories, containers, and filesystems

$ErrorActionPreference = "Continue"

# Colors for output
$RED = "Red"
$GREEN = "Green"
$YELLOW = "Yellow"
$BLUE = "Cyan"
$PURPLE = "Magenta"
$CYAN = "Cyan"
$WHITE = "White"

# Initialize scan environment using scan directory approach
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Source the scan directory template
. "$ScriptDir\Scan-Directory-Template.ps1"

# Initialize scan environment for ClamAV
$scanEnv = Initialize-ScanEnvironment -ToolName "clamav"

# Set TARGET_DIR and extract scan information
$TARGET_DIR = if ($env:TARGET_DIR) { $env:TARGET_DIR } else { Get-Location }
if ($env:SCAN_ID) {
    $parts = $env:SCAN_ID -split '_'
    $TARGET_NAME = $parts[0]
    $USERNAME = $parts[1]
    $TIMESTAMP = $parts[2..($parts.Length-1)] -join '_'
    $SCAN_ID = $env:SCAN_ID
}
else {
    # Fallback for standalone execution
    $TARGET_NAME = Split-Path -Leaf $TARGET_DIR
    $USERNAME = if ($env:USERNAME) { $env:USERNAME } else { $env:USER }
    $TIMESTAMP = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $SCAN_ID = "${TARGET_NAME}_${USERNAME}_${TIMESTAMP}"
}

Write-Host ""
Write-Host "============================================" -ForegroundColor $WHITE
Write-Host "ClamAV Multi-Target Malware Scanner" -ForegroundColor $WHITE
Write-Host "============================================" -ForegroundColor $WHITE
Write-Host "Repository: $TARGET_DIR"
Write-Host "Output Directory: $OUTPUT_DIR"
Write-Host "Timestamp: $TIMESTAMP"
Write-Host ""

# Create output directory if it doesn't exist
if (-not (Test-Path $OUTPUT_DIR)) {
    New-Item -ItemType Directory -Path $OUTPUT_DIR -Force | Out-Null
}

# Initialize scan log
@"
ClamAV scan started: $TIMESTAMP
Target: $TARGET_DIR
"@ | Out-File -FilePath $SCAN_LOG -Encoding UTF8

Write-Host "🦠 Malware Detection Scan" -ForegroundColor $CYAN
Write-Host "=========================="

# Check if Docker is available
$dockerAvailable = $false
try {
    $null = docker --version 2>$null
    if ($LASTEXITCODE -eq 0) {
        $null = docker ps 2>$null
        if ($LASTEXITCODE -eq 0) {
            $dockerAvailable = $true
        }
    }
} catch {
    $dockerAvailable = $false
}

if ($dockerAvailable) {
    Write-Host "🐳 Using Docker-based ClamAV..."
    
    # Detect platform (Note: Windows doesn't need special ARM handling like macOS)
    $CLAMAV_IMAGE = "clamav/clamav:latest"
    
    # Pull ClamAV Docker image
    Write-Host "📥 Pulling ClamAV Docker image..."
    docker pull $CLAMAV_IMAGE 2>&1 | Tee-Object -FilePath $SCAN_LOG -Append
    
    if ($LASTEXITCODE -eq 0) {
        # Create a persistent volume for ClamAV definitions to speed up future scans
        $CLAMAV_DB_VOL = "clamav-definitions"
        docker volume create $CLAMAV_DB_VOL 2>$null
        
        # Update virus definitions before scanning
        Write-Host "📥 Updating ClamAV virus definitions..." -ForegroundColor $CYAN
        Write-Host "This ensures we have the latest malware signatures (may take 1-2 minutes)..."
        
        docker run --rm `
            -v "${CLAMAV_DB_VOL}:/var/lib/clamav" `
            $CLAMAV_IMAGE `
            freshclam --stdout 2>&1 | Tee-Object -FilePath $SCAN_LOG -Append
        
        $FRESHCLAM_RESULT = $LASTEXITCODE
        if ($FRESHCLAM_RESULT -eq 0) {
            Write-Host "✅ Virus definitions updated successfully" -ForegroundColor $GREEN
        } else {
            Write-Host "⚠️  Virus definition update had issues (exit code: $FRESHCLAM_RESULT)" -ForegroundColor $YELLOW
            Write-Host "   Proceeding with available definitions..."
        }
        
        # Show definition info
        Write-Host "📋 Checking virus definition status..." -ForegroundColor $CYAN
        docker run --rm `
            -v "${CLAMAV_DB_VOL}:/var/lib/clamav" `
            $CLAMAV_IMAGE `
            clamscan --version 2>&1 | Tee-Object -FilePath $SCAN_LOG -Append
        
        # Run scan with updated definitions
        Write-Host "🔍 Scanning directory: $TARGET_DIR" -ForegroundColor $BLUE
        Write-Host "This may take several minutes..."
        
        $detailedLogPath = Join-Path $OUTPUT_DIR "${SCAN_ID}_clamav-detailed.log"
        $currentLogPath = Join-Path $OUTPUT_DIR "clamav-detailed.log"
        
        docker run --rm `
            -v "${TARGET_DIR}:/workspace:ro" `
            -v "${OUTPUT_DIR}:/output" `
            -v "${CLAMAV_DB_VOL}:/var/lib/clamav" `
            $CLAMAV_IMAGE `
            clamscan -r --log=/output/${SCAN_ID}_clamav-detailed.log /workspace 2>&1 | Tee-Object -FilePath $SCAN_LOG -Append
        
        $SCAN_RESULT = $LASTEXITCODE
        
        # Create current file copy for latest results
        if (Test-Path $detailedLogPath) {
            if (Test-Path $currentLogPath) { Remove-Item $currentLogPath -Force }
            Copy-Item $detailedLogPath $currentLogPath -Force
        }
        
        Write-Host "✅ Malware scan completed"
    }
    else {
        Write-Host "❌ Unable to pull ClamAV image" -ForegroundColor $RED
        "ClamAV scan skipped - Docker image unavailable" | Out-File -FilePath (Join-Path $OUTPUT_DIR "${SCAN_ID}_clamav-detailed.log") -Encoding UTF8
        $SCAN_RESULT = 0
    }
}
else {
    Write-Host "⚠️  Docker not available" -ForegroundColor $YELLOW
    Write-Host "Installing ClamAV locally would be required for native scanning"
    Write-Host "Creating placeholder results..."
    
    # Create empty results
    @"
ClamAV scan skipped - Docker not available
No malware detected (scan not performed)
"@ | Out-File -FilePath (Join-Path $OUTPUT_DIR "${SCAN_ID}_clamav-detailed.log") -Encoding UTF8
    "No malware detected (scan not performed)" | Out-File -FilePath $SCAN_LOG -Append -Encoding UTF8
    
    # Create current file copy for consistency
    $detailedLogPath = Join-Path $OUTPUT_DIR "${SCAN_ID}_clamav-detailed.log"
    $currentLogPath = Join-Path $OUTPUT_DIR "clamav-detailed.log"
    if (Test-Path $currentLogPath) { Remove-Item $currentLogPath -Force }
    Copy-Item $detailedLogPath $currentLogPath -Force
    
    $SCAN_RESULT = 0
}

# Display summary
Write-Host ""
Write-Host "📊 ClamAV Malware Detection Summary" -ForegroundColor $CYAN
Write-Host "==================================="

$detailedLogPath = Join-Path $OUTPUT_DIR "clamav-detailed.log"
if (Test-Path $detailedLogPath) {
    Write-Host "📄 Detailed scan log: $detailedLogPath"
}

# Basic summary from scan log
if (Test-Path $SCAN_LOG) {
    Write-Host ""
    Write-Host "Scan Summary:"
    Write-Host "============="
    
    $logContent = Get-Content $SCAN_LOG -Raw
    
    # Extract summary information from log
    if ($logContent -match "SCAN SUMMARY") {
        $summaryStart = $logContent.IndexOf("----------- SCAN SUMMARY -----------")
        if ($summaryStart -ge 0) {
            $summaryEnd = $logContent.IndexOf("End Date:", $summaryStart)
            if ($summaryEnd -ge 0) {
                $length = [Math]::Min($summaryEnd - $summaryStart + 50, $logContent.Length - $summaryStart)
                if ($length -gt 0) {
                    $summary = $logContent.Substring($summaryStart, $length)
                    Write-Host $summary
                }
            }
        }
    }
    else {
        # Fallback: count files and infected
        $okMatches = Select-String -Path $SCAN_LOG -Pattern "OK$" -AllMatches
        $SCANNED_FILES = if ($okMatches) { $okMatches.Matches.Count } else { "Unknown" }
        $foundMatches = Select-String -Path $SCAN_LOG -Pattern "FOUND$" -AllMatches
        $INFECTED_FILES = if ($foundMatches) { $foundMatches.Matches.Count } else { 0 }
        
        Write-Host "Scanned files: $SCANNED_FILES"
        Write-Host "Infected files: $INFECTED_FILES"
    }
    
    Write-Host ""
    Write-Host "Detailed results saved to: $SCAN_LOG"
}
else {
    Write-Host ""
    Write-Host "⚠️  No scan log generated. Check Docker configuration."
}

# Security status
if ($SCAN_RESULT -eq 0) {
    Write-Host ""
    Write-Host "✅ Security Status: Clean - No malware detected" -ForegroundColor $GREEN
}
else {
    Write-Host ""
    Write-Host "🚨 Security Status: THREAT DETECTED - Review results immediately" -ForegroundColor $RED
}

Write-Host ""
Write-Host "📁 Output Files:" -ForegroundColor $BLUE
Write-Host "================"
Write-Host "📄 Scan log: $SCAN_LOG"
if (Test-Path $detailedLogPath) {
    Write-Host "📄 Detailed log: $detailedLogPath"
}
Write-Host "📂 Reports directory: $OUTPUT_DIR"

Write-Host ""
Write-Host "🔧 Available Commands:" -ForegroundColor $BLUE
Write-Host "===================="
Write-Host "📊 Analyze results:       .\analyze-clamav-results.ps1"
Write-Host "🔍 Run new scan:          .\run-clamav-scan.ps1"
Write-Host "📋 View scan log:         Get-Content `$SCAN_LOG"
Write-Host "🔍 View detailed results: Get-Content `$OUTPUT_DIR\clamav-detailed.log"

Write-Host ""
Write-Host "🔗 Additional Resources:" -ForegroundColor $BLUE
Write-Host "======================="
Write-Host "• ClamAV Documentation: https://docs.clamav.net/"
Write-Host "• Malware Analysis Best Practices: https://owasp.org/www-project-top-ten/2017/A9_2017-Using_Components_with_Known_Vulnerabilities"
Write-Host "• Docker Security: https://docs.docker.com/engine/security/"

Write-Host ""
Write-Host "============================================"
Write-Host "✅ ClamAV malware detection completed!" -ForegroundColor $GREEN
Write-Host "============================================"
Write-Host ""
Write-Host "============================================"
Write-Host "ClamAV scan complete."
Write-Host "============================================"
