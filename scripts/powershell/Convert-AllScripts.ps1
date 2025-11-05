# Batch Shell to PowerShell Conversion Helper
# This script helps identify and track shell script conversions

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Shell to PowerShell Conversion Tracker" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Get all .sh files
$ShellScripts = Get-ChildItem -Path $ScriptDir -Filter "*.sh" | Sort-Object Name

# Get all .ps1 files
$PowerShellScripts = Get-ChildItem -Path $ScriptDir -Filter "*.ps1" | Sort-Object Name

Write-Host "📊 Conversion Status:" -ForegroundColor Yellow
Write-Host "===================="
Write-Host "Total Shell Scripts: $($ShellScripts.Count)"
Write-Host "Total PowerShell Scripts: $($PowerShellScripts.Count)"
Write-Host ""

# Check which scripts have been converted
$Converted = @()
$NotConverted = @()

foreach ($sh in $ShellScripts) {
    $baseName = $sh.BaseName
    $ps1Name = "$baseName.ps1"
    $ps1Path = Join-Path $ScriptDir $ps1Name
    
    if (Test-Path $ps1Path) {
        $Converted += $baseName
    } else {
        $NotConverted += $baseName
    }
}

Write-Host "✅ Converted Scripts ($($Converted.Count)):" -ForegroundColor Green
Write-Host "========================"
foreach ($script in $Converted) {
    Write-Host "  ✓ $script" -ForegroundColor Green
}
Write-Host ""

Write-Host "⏳ Pending Conversions ($($NotConverted.Count)):" -ForegroundColor Yellow
Write-Host "========================"
foreach ($script in $NotConverted) {
    Write-Host "  ○ $script" -ForegroundColor Yellow
}
Write-Host ""

# Categorize pending scripts
$ScannerScripts = $NotConverted | Where-Object { $_ -like "run-*-scan" }
$AnalysisScripts = $NotConverted | Where-Object { $_ -like "analyze-*" }
$ManagementScripts = $NotConverted | Where-Object { 
    $_ -like "*manage*" -or $_ -like "*resolve*" -or $_ -like "*aws*" 
}
$OtherScripts = $NotConverted | Where-Object { 
    $_ -notin $ScannerScripts -and 
    $_ -notin $AnalysisScripts -and 
    $_ -notin $ManagementScripts 
}

Write-Host "📋 Pending Scripts by Category:" -ForegroundColor Cyan
Write-Host "================================"
Write-Host ""

if ($ScannerScripts.Count -gt 0) {
    Write-Host "🔍 Scanner Scripts ($($ScannerScripts.Count)):" -ForegroundColor Blue
    foreach ($script in $ScannerScripts) {
        Write-Host "  • $script"
    }
    Write-Host ""
}

if ($AnalysisScripts.Count -gt 0) {
    Write-Host "📊 Analysis Scripts ($($AnalysisScripts.Count)):" -ForegroundColor Blue
    foreach ($script in $AnalysisScripts) {
        Write-Host "  • $script"
    }
    Write-Host ""
}

if ($ManagementScripts.Count -gt 0) {
    Write-Host "⚙️  Management Scripts ($($ManagementScripts.Count)):" -ForegroundColor Blue
    foreach ($script in $ManagementScripts) {
        Write-Host "  • $script"
    }
    Write-Host ""
}

if ($OtherScripts.Count -gt 0) {
    Write-Host "📦 Other Scripts ($($OtherScripts.Count)):" -ForegroundColor Blue
    foreach ($script in $OtherScripts) {
        Write-Host "  • $script"
    }
    Write-Host ""
}

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Conversion Progress: $($Converted.Count)/$($ShellScripts.Count) ($([math]::Round(($Converted.Count/$ShellScripts.Count)*100, 1))%)" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "💡 Next Steps:" -ForegroundColor Yellow
Write-Host "1. Review the pending conversions list above"
Write-Host "2. Convert scripts based on priority (scanners → analysis → management)"
Write-Host "3. Test each converted script to ensure functionality"
Write-Host "4. Update README-PowerShell-Conversion.md with completed conversions"
Write-Host ""

# Offer to create template files
Write-Host "Would you like to create template .ps1 files for pending conversions? (Y/N)" -ForegroundColor Yellow
$response = Read-Host

if ($response -eq 'Y' -or $response -eq 'y') {
    Write-Host ""
    Write-Host "Creating template files..." -ForegroundColor Cyan
    
    foreach ($script in $NotConverted) {
        $ps1Path = Join-Path $ScriptDir "$script.ps1"
        $shPath = Join-Path $ScriptDir "$script.sh"
        
        $template = @"
# PowerShell conversion of $script.sh
# TODO: Complete conversion from shell script

# Original shell script: $script.sh
# Conversion Status: IN PROGRESS

Write-Host "This script is under conversion from $script.sh" -ForegroundColor Yellow
Write-Host "Please refer to the original shell script for now." -ForegroundColor Yellow
Write-Host ""
Write-Host "Original script location: $shPath" -ForegroundColor Cyan

# TODO: Add converted PowerShell code here
"@
        
        $template | Out-File -FilePath $ps1Path -Encoding UTF8
        Write-Host "  Created: $script.ps1" -ForegroundColor Green
    }
    
    Write-Host ""
    Write-Host "✅ Template files created!" -ForegroundColor Green
    Write-Host "You can now edit each .ps1 file to complete the conversion." -ForegroundColor Cyan
}

Write-Host ""
Write-Host "Done!" -ForegroundColor Green
