#!/bin/bash

# Compliance Dashboard Launcher
# Opens the security compliance dashboard for audit tracking and user activity monitoring

# Color definitions
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
WHITE='\033[1;37m'
RED='\033[0;31m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
COMPLIANCE_DIR="$PROJECT_ROOT/reports/security-reports/compliance"
DASHBOARD_PATH="$COMPLIANCE_DIR/compliance-dashboard.html"

echo -e "${WHITE}============================================${NC}"
echo -e "${WHITE}🛡️  Security Compliance Dashboard Launcher${NC}"
echo -e "${WHITE}============================================${NC}"
echo

# Check if compliance directory exists
if [ ! -d "$COMPLIANCE_DIR" ]; then
    echo -e "${YELLOW}⚠️  Compliance directory not found. Creating it...${NC}"
    mkdir -p "$COMPLIANCE_DIR"
fi

# Check if dashboard exists, if not generate it
if [ ! -f "$DASHBOARD_PATH" ]; then
    echo -e "${YELLOW}📊 Compliance dashboard not found. Generating it...${NC}"
    
    # Source the compliance logger to generate dashboard
    if [ -f "$SCRIPT_DIR/compliance-logger.sh" ]; then
        source "$SCRIPT_DIR/compliance-logger.sh"
        generate_compliance_dashboard
    else
        echo -e "${RED}❌ Error: compliance-logger.sh not found!${NC}"
        echo "Please ensure the compliance logger script is in the same directory."
        exit 1
    fi
fi

if [ -f "$DASHBOARD_PATH" ]; then
    echo -e "${GREEN}✅ Compliance dashboard found: $DASHBOARD_PATH${NC}"
    echo -e "${BLUE}🚀 Opening compliance dashboard...${NC}"
    
    # Add cache-busting parameter to force browser refresh
    TIMESTAMP=$(date +%s)
    DASHBOARD_URL="file://$DASHBOARD_PATH?v=$TIMESTAMP"
    
    # Try different methods to open the dashboard
    if command -v open >/dev/null 2>&1; then
        # macOS
        open "$DASHBOARD_URL"
    elif command -v xdg-open >/dev/null 2>&1; then
        # Linux
        xdg-open "$DASHBOARD_URL"
    elif command -v start >/dev/null 2>&1; then
        # Windows (Git Bash)
        start "$DASHBOARD_PATH"
    else
        echo -e "${BLUE}💡 Please open the following file in your browser:${NC}"
        echo "   file://$DASHBOARD_PATH"
    fi
    
    echo
    echo -e "${GREEN}✅ Compliance dashboard launched!${NC}"
    echo
    echo -e "${BLUE}📊 Dashboard Features:${NC}"
    echo "• Real-time audit activity tracking"
    echo "• User identification and role detection"
    echo "• Security scan compliance scoring"
    echo "• Historical activity timeline"
    echo "• Enterprise-grade audit trails"
    echo "• CSV export for compliance reporting"
    echo
    echo -e "${BLUE}💡 Dashboard Tips:${NC}"
    echo "• Run security scans to see activity data"
    echo "• Use ./audit-logger.sh for manual audit entries"
    echo "• Export compliance reports for audits"
    echo "• Monitor user activity patterns"
    echo
    echo -e "${YELLOW}📁 Related Files:${NC}"
    echo "• Dashboard: $DASHBOARD_PATH"
    echo "• Audit CSV:  $COMPLIANCE_DIR/security-audit.csv"
    echo "• Logger:     $SCRIPT_DIR/compliance-logger.sh"
    
else
    echo -e "${RED}❌ Error: Could not create or find compliance dashboard!${NC}"
    echo "Please check permissions and try running the compliance logger manually:"
    echo "   ./compliance-logger.sh"
    exit 1
fi