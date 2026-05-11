#!/bin/bash
set -euo pipefail

OUTPUT_DIR=${1:-reports}
mkdir -p "$OUTPUT_DIR"

echo "Generating security report..."

# Check if checkov results exist
if [ -f "checkov-results.json" ]; then
    FAILED_CHECKS=$(cat checkov-results.json | jq '[.results.failed_checks | length] | add // 0')
    echo "Checkov failed checks: $FAILED_CHECKS"
    
    if [ "$FAILED_CHECKS" -gt 0 ]; then
        echo "::error::Security scan found $FAILED_CHECKS issues"
        cat checkov-results.json | jq -r '.results.failed_checks[] | 
            "  - \(.check_id): \(.check_name) in \(.resource)"'
    fi
fi

# Check tfsec results
if [ -f "tfsec-results.json" ]; then
    SEVERITY_COUNT=$(cat tfsec-results.json | jq '[.results[] | .severity] | group_by(.) | map({(.[0]): length}) | add')
    echo "Tfsec findings by severity: $SEVERITY_COUNT"
fi

# Generate markdown summary for PR comment
cat > "$OUTPUT_DIR/security-summary.md" << 'EOF'
## 🔒 Security Scan Results

| Tool | Status | Details |
|------|--------|---------|
| Checkov | ${CHECKOV_STATUS} | ${CHECKOV_DETAILS} |
| Tfsec | ${TFSEC_STATUS} | ${TFSEC_DETAILS} |

### Critical Findings
${CRITICAL_FINDINGS}
EOF

echo "Report saved to $OUTPUT_DIR/security-summary.md"