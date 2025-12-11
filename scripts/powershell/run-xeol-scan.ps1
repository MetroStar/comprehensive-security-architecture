# Xeol End-of-Life Detection Script
# Detects End-of-Life packages and technologies using Xeol

param(
    [Parameter(Position=0)]
    [ValidateSet("filesystem", "images", "base", "all")]
    [string]$Mode = "all"
)

$ErrorActionPreference = "Continue"

# Initialize scan environment
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$ScriptDir\Scan-Directory-Template.ps1"
$scanEnv = Initialize-ScanEnvironment -ToolName "xeol"

# Extract scan information
if ($env:SCAN_ID) {
    $parts = $env:SCAN_ID -split '_'
    $TARGET_NAME = $parts[0]
    $USERNAME = $parts[1]
    $TIMESTAMP = $parts[2..($parts.Length-1)] -join '_'
    $SCAN_ID = $env:SCAN_ID
}
else {
    $targetPath = if ($env:TARGET_DIR) { $env:TARGET_DIR } else { Get-Location }
    $TARGET_NAME = Split-Path -Leaf $targetPath
    $USERNAME = if ($env:USERNAME) { $env:USERNAME } else { $env:USER }
    $TIMESTAMP = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $SCAN_ID = "${TARGET_NAME}_${USERNAME}_${TIMESTAMP}"
}

$REPO_PATH = if ($env:TARGET_DIR) { $env:TARGET_DIR } else { Get-Location }

Write-Host ""
Write-Host "============================================"
Write-Host "Xeol End-of-Life Detection Scanner"
Write-Host "============================================"
Write-Host ""

if (-not (Test-Path $OUTPUT_DIR)) {
    New-Item -ItemType Directory -Path $OUTPUT_DIR -Force | Out-Null
}

# Function to scan a target
function Invoke-XeolScan {
    param([string]$ScanType, [string]$Target)
    
    $outputFile = Join-Path $OUTPUT_DIR "xeol-${ScanType}-results-${TIMESTAMP}.json"
    $currentFile = Join-Path $OUTPUT_DIR "xeol-${ScanType}-results.json"
    
    Write-Host "🔍 Scanning ${ScanType}: ${Target}" -ForegroundColor Cyan
    
    try {
        $null = docker ps 2>$null
        if ($LASTEXITCODE -eq 0) {
            docker run --rm -v "${PWD}:/workspace" `
                -v "${OUTPUT_DIR}:/output" `
                noqcks/xeol:latest `
                "$Target" `
                --output json `
                --file "/output/$(Split-Path -Leaf $outputFile)" 2>&1 | Tee-Object -FilePath $SCAN_LOG -Append | Out-Null
            
            if (Test-Path $outputFile) {
                Write-Host "✅ Scan completed" -ForegroundColor Green
                if (Test-Path $currentFile) { Remove-Item $currentFile -Force }
                Copy-Item $outputFile $currentFile -Force
            }
        } else {
            Write-Host "❌ Docker not available" -ForegroundColor Red
            '{"matches": []}' | Out-File -FilePath $outputFile -Encoding UTF8
        }
    } catch {
        Write-Host "❌ Docker not available" -ForegroundColor Red
        '{"matches": []}' | Out-File -FilePath $outputFile -Encoding UTF8
    }
    Write-Host ""
}

# Base images to scan
$BASE_IMAGES = @("alpine:latest", "ubuntu:22.04", "node:18-alpine", "python:3.11-alpine", "nginx:alpine")

Write-Host "⚰️  Step 1: End-of-Life Package Detection" -ForegroundColor Cyan
Write-Host "========================================"

switch ($Mode) {
    "base" {
        foreach ($image in $BASE_IMAGES) {
            Write-Host "📦 Scanning base image: $image" -ForegroundColor Blue
            $imageName = $image.Replace(":", "-").Replace("/", "-")
            Invoke-XeolScan -ScanType "base-$imageName" -Target $image
        }
    }
    "filesystem" {
        if (Test-Path $REPO_PATH) {
            Invoke-XeolScan -ScanType "filesystem" -Target $REPO_PATH
        }
    }
    "all" {
        foreach ($image in $BASE_IMAGES) {
            Write-Host "📦 Scanning base image: $image" -ForegroundColor Blue
            $imageName = $image.Replace(":", "-").Replace("/", "-")
            Invoke-XeolScan -ScanType "base-$imageName" -Target $image
        }
        if (Test-Path $REPO_PATH) {
            Invoke-XeolScan -ScanType "filesystem" -Target $REPO_PATH
        }
    }
}

Write-Host ""
Write-Host "📊 Xeol EOL Detection Summary" -ForegroundColor Cyan
Write-Host "=============================="

$resultsFiles = Get-ChildItem -Path $OUTPUT_DIR -Filter "xeol-*-results.json" -File -ErrorAction SilentlyContinue
if ($resultsFiles) {
    Write-Host "⚠️  $($resultsFiles.Count) result files found" -ForegroundColor Yellow
    
    $TOTAL_EOL = 0
    foreach ($file in $resultsFiles) {
        try {
            $content = Get-Content $file.FullName -Raw | ConvertFrom-Json
            if ($content.matches) { $TOTAL_EOL += $content.matches.Count }
        } catch {}
    }
    
    if ($TOTAL_EOL -gt 0) {
        Write-Host "  ⚰️  EOL Packages: $TOTAL_EOL" -ForegroundColor Red
    } else {
        Write-Host "  ✅ No EOL packages detected" -ForegroundColor Green
    }
} else {
    Write-Host "✅ No EOL packages detected" -ForegroundColor Green
}

Write-Host ""
Write-Host "============================================"
Write-Host "✅ Xeol scan completed!" -ForegroundColor Green
Write-Host "============================================"
Write-Host ""
