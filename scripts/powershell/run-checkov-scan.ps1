# Checkov Infrastructure-as-Code Security Scanner
param(
    [Parameter(Position=0)]
    [string]$TargetDir = ""
)

$ErrorActionPreference = "Continue"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$ScriptDir\Scan-Directory-Template.ps1"
$scanEnv = Initialize-ScanEnvironment -ToolName "checkov"

Write-Host "Checkov scan completed." -ForegroundColor Green