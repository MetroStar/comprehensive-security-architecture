// Real-time activity data loaded from CSV audit logs
function loadRealActivityData() {
    const realActivities = [
        ['timestamp', 'user_id (real_user)', 'hostname', 'script_name', 'action', 'target_directory', 'results_found', 'ERROR'],
        ['2025-11-13 18:44:54', 'rnelson (rnelson)', 'ITLP01183.local', 'example-audited-checkov.sh', 'SCRIPT_START', 'bash', '0', 'ERROR'],
        ['2025-11-13 18:44:54', 'rnelson (rnelson)', 'ITLP01183.local', 'example-audited-checkov.sh', 'SCRIPT_COMPLETE', 'bash', '23', 'ERROR'],
    ];
    
    // Update the dashboard with real data
    const tbody = document.getElementById('activityBody');
    if (realActivities.length > 0) {
        tbody.innerHTML = realActivities.map(row => 
            `<tr>
                <td>${row[0]}</td>
                <td><strong>${row[1]}</strong></td>
                <td>${row[2]}</td>
                <td><span style="background: #3498db; color: white; padding: 2px 8px; border-radius: 12px; font-size: 0.85em;">${row[3]}</span></td>
                <td>${row[4]}</td>
                <td style="font-family: monospace; font-size: 0.9em; color: #666;">${row[5]}</td>
                <td><span style="background: ${row[6] > 0 ? '#f39c12' : '#27ae60'}; color: white; padding: 2px 8px; border-radius: 12px; font-size: 0.85em;">${row[6]}</span></td>
                <td class="status-${row[7] === 'SUCCESS' ? 'success' : row[7] === 'WARNING' ? 'warning' : 'error'}">${row[7]}</td>
            </tr>`
        ).join('');
    } else {
        tbody.innerHTML = '<tr><td colspan="8">No security activities recorded yet.</td></tr>';
    }
}

// Load real data when called
loadRealActivityData();
