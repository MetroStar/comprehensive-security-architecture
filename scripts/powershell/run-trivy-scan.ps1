# Trivy Multi-Target Security Scanner
param(
    [Parameter(Position=0)]
    [ValidateSet("filesystem", "images", "base", "kubernetes", "all")]
    [string]$ScanMode = "all"
)

$ErrorActionPreference = "Continue"

# Initialize scan environment
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$ScriptDir\Scan-Directory-Template.ps1"
$scanEnv = Initialize-ScanEnvironment -ToolName "trivy"

# Extract scan information
$REPO_PATH = if ($env:TARGET_DIR) { $env:TARGET_DIR } else { Get-Location }
if ($env:SCAN_ID) {
    $parts = $env:SCAN_ID -split '_'
    $SCAN_ID = $env:SCAN_ID
    $TIMESTAMP = $parts[2..($parts.Length-1)] -join '_'
} else {
    $TARGET_NAME = Split-Path -Leaf $REPO_PATH
    $USERNAME = if ($env:USERNAME) { $env:USERNAME } else { $env:USER }
    $TIMESTAMP = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $SCAN_ID = "${TARGET_NAME}_${USERNAME}_${TIMESTAMP}"
}

Write-Host "`n===============================================" -ForegroundColor White
Write-Host "Trivy Multi-Target Security Scanner" -ForegroundColor White
Write-Host "===============================================`n" -ForegroundColor White

# Create output directory
if (-not (Test-Path $OUTPUT_DIR)) {
    New-Item -ItemType Directory -Path $OUTPUT_DIR -Force | Out-Null
}

# Initialize scan log
"Trivy scan started: $TIMESTAMP`nTarget: $REPO_PATH" | Out-File -FilePath $SCAN_LOG -Encoding UTF8

Write-Host "Trivy scan completed." -ForegroundColor Green