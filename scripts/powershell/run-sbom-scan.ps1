# SBOM (Software Bill of Materials) Generation Script (PowerShell)
# Generates comprehensive software inventory using Syft from Anchore

param(
    [Parameter(Position=0)]
    [string]$TargetPath = ""
)

# Support target directory scanning
if ([string]::IsNullOrWhiteSpace($TargetPath)) {
    $TargetPath = if ($env:TARGET_DIR) { $env:TARGET_DIR } else { Get-Location }
}

# Initialize scan environment using scan directory approach
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Source the scan directory template
. "$ScriptDir\Scan-Directory-Template.ps1"

# Initialize scan environment for SBOM
$scanEnv = Initialize-ScanEnvironment -ToolName "sbom"

# Extract scan information
if ($env:SCAN_ID) {
    $parts = $env:SCAN_ID -split '_'
    $TARGET_NAME = $parts[0]
    $USERNAME = $parts[1]
    $TIMESTAMP = $parts[2..($parts.Length-1)] -join '_'
    $SCAN_ID = $env:SCAN_ID
}
else {
    $TARGET_NAME = Split-Path -Leaf $TargetPath
    $USERNAME = if ($env:USERNAME) { $env:USERNAME } else { $env:USER }
    $TIMESTAMP = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $SCAN_ID = "${TARGET_NAME}_${USERNAME}_${TIMESTAMP}"
}

Write-Host "============================================"
Write-Host "SBOM Generation with Syft"
Write-Host "============================================"
Write-Host "Target: $TargetPath"
Write-Host "Output Directory: $OUTPUT_DIR"
Write-Host "Scan ID: $SCAN_ID"
Write-Host "Started: $(Get-Date)"
Write-Host ""

# Initialize scan log
"SBOM generation started: $TIMESTAMP" | Out-File -FilePath $SCAN_LOG
"Target: $TargetPath" | Out-File -FilePath $SCAN_LOG -Append
"Syft version check:" | Out-File -FilePath $SCAN_LOG -Append

# Function to detect project metadata
function Get-ProjectInfo {
    param([string]$Path)
    
    $projectName = ""
    $projectVersion = ""
    
    # Try to extract project info from various manifest files
    if (Test-Path "$Path\package.json") {
        $pkg = Get-Content "$Path\package.json" | ConvertFrom-Json
        $projectName = $pkg.name
        $projectVersion = $pkg.version
    }
    elseif (Test-Path "$Path\pyproject.toml") {
        $content = Get-Content "$Path\pyproject.toml" -Raw
        if ($content -match 'name\s*=\s*"([^"]+)"') { $projectName = $Matches[1] }
        if ($content -match 'version\s*=\s*"([^"]+)"') { $projectVersion = $Matches[1] }
    }
    elseif (Test-Path "$Path\go.mod") {
        $firstLine = Get-Content "$Path\go.mod" -First 1
        if ($firstLine -match 'module\s+(.+)') { $projectName = $Matches[1] }
    }
    elseif (Test-Path "$Path\pom.xml") {
        $xml = [xml](Get-Content "$Path\pom.xml")
        $projectName = $xml.project.artifactId
        $projectVersion = $xml.project.version
    }
    elseif (Test-Path "$Path\Cargo.toml") {
        $content = Get-Content "$Path\Cargo.toml" -Raw
        if ($content -match 'name\s*=\s*"([^"]+)"') { $projectName = $Matches[1] }
        if ($content -match 'version\s*=\s*"([^"]+)"') { $projectVersion = $Matches[1] }
    }
    
    # Fallback to directory name
    if ([string]::IsNullOrWhiteSpace($projectName)) {
        $projectName = Split-Path -Leaf $Path
    }
    
    if ([string]::IsNullOrWhiteSpace($projectVersion)) {
        $projectVersion = "unknown"
    }
    
    return @{
        Name = $projectName
        Version = $projectVersion
    }
}

# Function to generate SBOM
function New-SBOM {
    param(
        [string]$ScanType,
        [string]$Target,
        [string]$OutputFile
    )
    
    Write-Host "🔍 Generating SBOM for ${ScanType}: ${Target}" -ForegroundColor Cyan
    "Generating SBOM for ${ScanType}: ${Target}" | Out-File -FilePath $SCAN_LOG -Append
    
    # Detect project information
    $projectInfo = Get-ProjectInfo -Path $Target
    Write-Host "📋 Project: $($projectInfo.Name) ($($projectInfo.Version))" -ForegroundColor Blue
    "Project: $($projectInfo.Name) ($($projectInfo.Version))" | Out-File -FilePath $SCAN_LOG -Append
    
    $success = $false
    
    # Try local Syft installation
    if (Get-Command syft -ErrorAction SilentlyContinue) {
        Write-Host "✅ Using local Syft installation" -ForegroundColor Green
        & syft version 2>&1 | Out-File -FilePath $SCAN_LOG -Append
        
        try {
            & syft $Target -o json --name $projectInfo.Name --version $projectInfo.Version > $OutputFile 2>> $SCAN_LOG
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✅ SBOM generated successfully: $(Split-Path -Leaf $OutputFile)" -ForegroundColor Green
                "SBOM generated successfully: $OutputFile" | Out-File -FilePath $SCAN_LOG -Append
                $success = $true
            }
        }
        catch {
            Write-Host "❌ Failed to generate SBOM for $ScanType" -ForegroundColor Red
            "Failed to generate SBOM for $ScanType" | Out-File -FilePath $SCAN_LOG -Append
        }
    }
    # Try Docker version
    elseif (Get-Command docker -ErrorAction SilentlyContinue) {
        Write-Host "⚠️  Local Syft not found, using Docker version" -ForegroundColor Yellow
        "Using Docker version of Syft" | Out-File -FilePath $SCAN_LOG -Append
        
        try {
            $targetEscaped = $Target -replace '\\', '/'
            & docker run --rm -v "${targetEscaped}:/workspace" anchore/syft:latest /workspace -o json --name $projectInfo.Name --version $projectInfo.Version > $OutputFile 2>> $SCAN_LOG
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✅ SBOM generated successfully: $(Split-Path -Leaf $OutputFile)" -ForegroundColor Green
                "SBOM generated successfully: $OutputFile" | Out-File -FilePath $SCAN_LOG -Append
                $success = $true
            }
        }
        catch {
            Write-Host "❌ Failed to generate SBOM for $ScanType using Docker" -ForegroundColor Red
            "Failed to generate SBOM for $ScanType using Docker" | Out-File -FilePath $SCAN_LOG -Append
        }
    }
    else {
        Write-Host "❌ Neither Syft nor Docker available for SBOM generation" -ForegroundColor Red
        "Neither Syft nor Docker available for SBOM generation" | Out-File -FilePath $SCAN_LOG -Append
    }
    
    # Create error placeholder if failed
    if (-not $success) {
        $errorSbom = @{
            artifacts = @()
            artifactRelationships = @()
            source = @{
                type = "directory"
                target = $Target
            }
            distro = @{}
            descriptor = @{
                name = "syft"
                version = "error"
            }
        }
        $errorSbom | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputFile
    }
    
    # Display SBOM summary
    if ((Test-Path $OutputFile) -and ((Get-Item $OutputFile).Length -gt 0)) {
        try {
            $sbomData = Get-Content $OutputFile | ConvertFrom-Json
            $artifactCount = $sbomData.artifacts.Count
            Write-Host "📊 SBOM Summary: $artifactCount artifacts cataloged" -ForegroundColor Blue
            "SBOM Summary: $artifactCount artifacts cataloged" | Out-File -FilePath $SCAN_LOG -Append
            
            # Show top package types
            Write-Host "📦 Package Types:" -ForegroundColor Cyan
            $sbomData.artifacts | Group-Object -Property type | Sort-Object -Property Count -Descending | Select-Object -First 5 | ForEach-Object {
                Write-Host "  $($_.Name): $($_.Count)"
            }
        }
        catch {
            # Silently continue if JSON parsing fails
        }
    }
    
    "" | Out-File -FilePath $SCAN_LOG -Append
}

# Generate SBOM for filesystem
$sbomFile = Join-Path $OUTPUT_DIR "${SCAN_ID}_sbom-filesystem.json"
New-SBOM -ScanType "filesystem" -Target $TargetPath -OutputFile $sbomFile

# Create current symlink
Push-Location $OUTPUT_DIR
try {
    if (Test-Path "sbom-filesystem.json") { Remove-Item "sbom-filesystem.json" -Force }
    try {
        New-Item -ItemType SymbolicLink -Path "sbom-filesystem.json" -Target (Split-Path -Leaf $sbomFile) -ErrorAction SilentlyContinue | Out-Null
    }
    catch {
        Copy-Item $sbomFile "sbom-filesystem.json" -Force
    }
}
finally {
    Pop-Location
}

Write-Host ""
Write-Host "============================================"
Write-Host "SBOM Generation Summary"
Write-Host "============================================"
Write-Host "Scan ID: $SCAN_ID"
Write-Host "Target: $TargetPath"
Write-Host "Output Directory: $OUTPUT_DIR"
Write-Host "Completed: $(Get-Date)"
Write-Host ""

# Generate summary JSON
$summaryFile = Join-Path $OUTPUT_DIR "${SCAN_ID}_sbom-summary.json"
$summary = @{
    scan_id = $SCAN_ID
    target = $TargetPath
    timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    sbom_files = @(
        @{
            type = "filesystem"
            file = (Split-Path -Leaf $sbomFile)
            path = $sbomFile
        }
    )
}
$summary | ConvertTo-Json -Depth 10 | Out-File -FilePath $summaryFile

Complete-ScanResults -ToolName "sbom"

exit 0
