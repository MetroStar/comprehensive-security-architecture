# Grype Multi-Target Vulnerability Scanner
param(
    [Parameter(Position=0)]
    [ValidateSet("filesystem", "images", "base", "all")]
    [string]$ScanMode = "all"
)

$ErrorActionPreference = "Continue"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$ScriptDir\Scan-Directory-Template.ps1"
$scanEnv = Initialize-ScanEnvironment -ToolName "grype"

Write-Host "Grype scan completed." -ForegroundColor Green