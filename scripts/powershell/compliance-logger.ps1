# Security Compliance Logger (PowerShell)
# Compliance Dashboard Integration  
# Creates CSV audit logs for compliance dashboards and reporting

param(
    [string]$Action,
    [string]$User,
    [string]$Script,
    [string]$Tool,
    [string]$Target,
    [string]$Duration,
    [int]$Findings = 0,
    [string]$Status = "SUCCESS"
)

# Get script directory and project paths
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent (Split-Path -Parent $ScriptDir)
$ComplianceDir = Join-Path $ProjectRoot "reports\security-reports\compliance"
$AuditFile = Join-Path $ComplianceDir "security-audit.csv"

# Ensure compliance directory exists
if (-not (Test-Path $ComplianceDir)) {
    New-Item -ItemType Directory -Path $ComplianceDir -Force | Out-Null
}

# Function to log compliance events
function Write-ComplianceLog {
    param(
        [string]$EventType,
        [string]$UserName = $env:USERNAME,
        [string]$ScriptName,
        [string]$ToolName,
        [string]$TargetPath,
        [string]$ExecutionTime,
        [int]$FindingCount = 0,
        [string]$EventStatus = "SUCCESS"
    )
    
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $UserInfo = "$UserName ($env:COMPUTERNAME)"
    
    # Create CSV header if file doesn't exist
    if (-not (Test-Path $AuditFile)) {
        $Header = "Timestamp,User,Script,Tool,Target,Duration,Findings,Status"
        $Header | Out-File -FilePath $AuditFile -Encoding UTF8
    }
    
    # Create audit entry
    $AuditEntry = "$Timestamp,$UserInfo,$ScriptName,$ToolName,$TargetPath,$ExecutionTime,$FindingCount,$EventStatus"
    $AuditEntry | Out-File -FilePath $AuditFile -Append -Encoding UTF8
    
    Write-Host "📋 Audit logged: $EventType for $UserName" -ForegroundColor Green
}

# Function to generate compliance dashboard
function New-ComplianceDashboard {
    $DashboardFile = Join-Path $ComplianceDir "compliance-dashboard.html"
    
    Write-Host "📊 Generating compliance dashboard..." -ForegroundColor Cyan
    
    $DashboardContent = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Security Compliance Dashboard</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { 
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; 
            background: linear-gradient(135deg, #0F1F3D 0%, #1a2332 50%, #C41E3A 100%);
            min-height: 100vh;
            padding: 20px;
        }
        .container { 
            max-width: 1400px; 
            margin: 0 auto; 
            background: rgba(255,255,255,0.95);
            border-radius: 15px;
            padding: 30px;
            box-shadow: 0 20px 40px rgba(0,0,0,0.1);
        }
        .header { 
            text-align: center; 
            margin-bottom: 40px;
            padding-bottom: 20px;
            border-bottom: 3px solid #3498db;
        }
        .header h1 {
            color: #2c3e50;
            font-size: 2.5em;
            margin-bottom: 10px;
            text-shadow: 2px 2px 4px rgba(0,0,0,0.1);
        }
        .metrics-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px;
            margin-bottom: 40px;
        }
        .metric-card {
            background: white;
            padding: 25px;
            border-radius: 12px;
            box-shadow: 0 8px 16px rgba(0,0,0,0.1);
            text-align: center;
            border-left: 5px solid #3498db;
            transition: transform 0.3s ease;
        }
        .metric-card:hover { transform: translateY(-5px); }
        .metric-value {
            font-size: 2.5em;
            font-weight: bold;
            color: #2c3e50;
            margin-bottom: 10px;
        }
        .metric-label {
            color: #7f8c8d;
            font-size: 1.1em;
            text-transform: uppercase;
            letter-spacing: 1px;
        }
        .activity-section {
            background: white;
            padding: 30px;
            border-radius: 12px;
            box-shadow: 0 8px 16px rgba(0,0,0,0.1);
            margin-bottom: 30px;
        }
        .section-title {
            color: #2c3e50;
            font-size: 1.8em;
            margin-bottom: 20px;
            padding-bottom: 10px;
            border-bottom: 2px solid #ecf0f1;
        }
        .activity-table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 20px;
        }
        .activity-table th,
        .activity-table td {
            padding: 12px;
            text-align: left;
            border-bottom: 1px solid #ecf0f1;
        }
        .activity-table th {
            background-color: #f8f9fa;
            font-weight: 600;
            color: #2c3e50;
            text-transform: uppercase;
            font-size: 0.9em;
            letter-spacing: 0.5px;
        }
        .status-success { color: #27ae60; font-weight: bold; }
        .status-warning { color: #f39c12; font-weight: bold; }
        .status-error { color: #e74c3c; font-weight: bold; }
        .user-summary {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
            gap: 20px;
            margin-top: 20px;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🛡️ Security Compliance Dashboard</h1>
            <p style="color: #7f8c8d; font-size: 1.2em; margin-top: 10px;">Enterprise Security Audit & Activity Monitoring</p>
        </div>
        
        <div class="metrics-grid">
            <div class="metric-card">
                <div class="metric-value" id="totalScans">Loading...</div>
                <div class="metric-label">Total Scans</div>
            </div>
            <div class="metric-card">
                <div class="metric-value" id="activeUsers">Loading...</div>
                <div class="metric-label">Active Users</div>
            </div>
            <div class="metric-card">
                <div class="metric-value" id="criticalFindings">Loading...</div>
                <div class="metric-label">Total Findings</div>
            </div>
            <div class="metric-card">
                <div class="metric-value" id="complianceScore">Loading...</div>
                <div class="metric-label">Compliance Score</div>
            </div>
        </div>
        
        <div class="activity-section">
            <h2 class="section-title">📊 Recent Security Activities</h2>
            <table class="activity-table">
                <thead>
                    <tr>
                        <th>Timestamp</th>
                        <th>User</th>
                        <th>Script</th>
                        <th>Tool</th>
                        <th>Target</th>
                        <th>Duration</th>
                        <th>Findings</th>
                        <th>Status</th>
                    </tr>
                </thead>
                <tbody id="activityBody">
                    <tr><td colspan="8" style="text-align: center; padding: 20px; color: #7f8c8d;">Loading audit data...</td></tr>
                </tbody>
            </table>
        </div>
        
        <div class="activity-section">
            <h2 class="section-title">👥 User Activity Summary</h2>
            <div class="user-summary" id="userSummary">
                <div style="background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); text-align: center; color: #7f8c8d;">Loading user activity data...</div>
            </div>
        </div>
    </div>

    <script src="activity-data.js"></script>
</body>
</html>
"@

    $DashboardContent | Out-File -FilePath $DashboardFile -Encoding UTF8
    
    # Generate activity data JavaScript file
    New-ActivityDataFile
    
    Write-Host "📊 Compliance dashboard generated: $DashboardFile" -ForegroundColor Green
}

# Function to create activity data JavaScript file
function New-ActivityDataFile {
    $ActivityDataFile = Join-Path $ComplianceDir "activity-data.js"
    
    $JSContent = @"
// Load real audit data from CSV
document.addEventListener('DOMContentLoaded', function() {
    fetch('security-audit.csv')
        .then(response => response.text())
        .then(csvData => {
            const realActivities = parseCSV(csvData);
            updateDashboardWithRealData(realActivities);
        })
        .catch(error => {
            console.log('No audit data found yet, showing empty state');
            updateDashboardWithRealData([]);
        });
});

function parseCSV(csvText) {
    const lines = csvText.split('\n');
    return lines.map(line => {
        const result = [];
        let current = '';
        let inQuotes = false;
        
        for (let i = 0; i < line.length; i++) {
            const char = line[i];
            if (char === '"') {
                inQuotes = !inQuotes;
            } else if (char === ',' && !inQuotes) {
                result.push(current.trim());
                current = '';
            } else {
                current += char;
            }
        }
        result.push(current.trim());
        return result;
    });
}

function updateDashboardWithRealData(realActivities) {
    // Calculate real metrics from actual data
    const totalScans = Math.max(0, realActivities.length - 1); // Subtract 1 for header row
    const uniqueUsers = [...new Set(realActivities.slice(1).map(row => row[1] ? row[1].split(' (')[0] : ''))].filter(u => u).length;
    const totalFindings = realActivities.slice(1).reduce((sum, row) => sum + parseInt(row[6] || 0), 0);
    const successfulScans = realActivities.slice(1).filter(row => row[7] === 'SUCCESS').length;
    const complianceScore = totalScans > 0 ? Math.round((successfulScans / totalScans) * 100) : 0;
    
    // Update metrics with real data
    document.getElementById('totalScans').textContent = totalScans;
    document.getElementById('activeUsers').textContent = uniqueUsers;
    document.getElementById('criticalFindings').textContent = totalFindings;
    document.getElementById('complianceScore').textContent = complianceScore + '%';
    
    // Update the activity table with real data
    const tbody = document.getElementById('activityBody');
    if (realActivities.length > 1) { // Skip header row
        tbody.innerHTML = realActivities.slice(1).filter(row => row[0] && row[0].trim()).map(row => 
            `<tr>
                <td>${row[0] || ''}</td>
                <td><strong>${row[1] || ''}</strong></td>
                <td>${row[2] || ''}</td>
                <td><span style="background: #3498db; color: white; padding: 2px 8px; border-radius: 12px; font-size: 0.85em;">${row[3] || ''}</span></td>
                <td>${row[4] || ''}</td>
                <td style="font-family: monospace; font-size: 0.9em; color: #666;">${row[5] || ''}</td>
                <td><span style="background: ${(row[6] && parseInt(row[6]) > 0) ? '#f39c12' : '#27ae60'}; color: white; padding: 2px 8px; border-radius: 12px; font-size: 0.85em;">${row[6] || '0'}</span></td>
                <td class="status-${(row[7] === 'SUCCESS') ? 'success' : (row[7] === 'WARNING') ? 'warning' : 'error'}">${row[7] || 'UNKNOWN'}</td>
            </tr>`
        ).join('');
        
        // Update user summary with real data
        const userStats = {};
        realActivities.slice(1).filter(row => row[0] && row[0].trim()).forEach(row => {
            const user = (row[1] || '').split(' (')[0]; // Extract main username
            if (user && user.trim()) {
                if (!userStats[user]) {
                    userStats[user] = { scans: 0, tools: new Set(), lastActive: row[0], findings: 0 };
                }
                userStats[user].scans++;
                userStats[user].tools.add(row[3] || 'unknown');
                userStats[user].findings += parseInt(row[6] || 0);
                if (row[0] > userStats[user].lastActive) {
                    userStats[user].lastActive = row[0];
                }
            }
        });
        
        const userSummaryDiv = document.getElementById('userSummary');
        if (Object.keys(userStats).length > 0) {
            userSummaryDiv.innerHTML = Object.entries(userStats).map(([user, stats]) => {
                const isBot = user.includes('bot') || user.includes('automated');
                const lastActiveTime = (stats.lastActive || '').split(' ')[1] || 'Unknown';
                return `<div style="background: white; padding: 15px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); border-left: 4px solid ${isBot ? '#9b59b6' : '#3498db'};">
                    <div style="font-weight: bold; color: #2c3e50; margin-bottom: 5px;">👤 ${user}</div>
                    <div style="font-size: 0.9em; color: #7f8c8d; margin-bottom: 8px;">
                        📊 ${stats.scans} scans • 🕐 Last: ${lastActiveTime}
                    </div>
                    <div style="font-size: 0.8em; color: #34495e;">
                        🔧 ${Array.from(stats.tools).join(', ')} • 🎯 ${stats.findings} findings
                    </div>
                    <div style="margin-top: 8px;">
                        <span style="background: ${isBot ? '#9b59b6' : '#27ae60'}; color: white; padding: 2px 8px; border-radius: 12px; font-size: 0.75em; text-transform: uppercase;">
                            ${isBot ? 'BOT' : 'HUMAN'}
                        </span>
                    </div>
                </div>`;
            }).join('');
        } else {
            userSummaryDiv.innerHTML = '<div style="background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); text-align: center; color: #7f8c8d;">👥 No user activity recorded yet</div>';
        }
        
    } else {
        tbody.innerHTML = '<tr><td colspan="8" style="text-align: center; padding: 20px; color: #7f8c8d;">📋 No security activities recorded yet. Run a security scan to see audit data here.</td></tr>';
        
        // Show empty state for user summary
        const userSummaryDiv = document.getElementById('userSummary');
        userSummaryDiv.innerHTML = '<div style="background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); text-align: center; color: #7f8c8d;">👥 No user activity recorded yet</div>';
    }
}
"@

    $JSContent | Out-File -FilePath $ActivityDataFile -Encoding UTF8
}

# Main execution logic
if ($Action) {
    Write-ComplianceLog -EventType $Action -UserName $User -ScriptName $Script -ToolName $Tool -TargetPath $Target -ExecutionTime $Duration -FindingCount $Findings -EventStatus $Status
} else {
    # Generate dashboard if called without parameters
    New-ComplianceDashboard
    Write-Host "✅ Compliance dashboard ready!" -ForegroundColor Green
    Write-Host "Use .\open-compliance-dashboard.ps1 to view it" -ForegroundColor Cyan
}

# Export functions for use by other scripts
# (PowerShell doesn't have direct export like bash, but these functions are available when dot-sourced)