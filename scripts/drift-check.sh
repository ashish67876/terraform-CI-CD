#!/bin/bash
set -euo pipefail

DIR=${1:-.}
ENV=$(basename $(dirname $DIR))

cd "$DIR"

echo "Checking for drift in $ENV..."

terraform init -backend=true -input=false

# Run plan with detailed exit codes
# 0 = no changes, 1 = error, 2 = changes detected (drift!)
set +e
terraform plan -detailed-exitcode -input=false -out=tfplan-drift
EXIT_CODE=$?
set -e

case $EXIT_CODE in
    0)
        echo "✅ No drift detected in $ENV"
        exit 0
        ;;
    1)
        echo "❌ Error running terraform plan"
        exit 1
        ;;
    2)
        echo "⚠️ DRIFT DETECTED in $ENV!"
        echo "::warning::Infrastructure drift found in $ENV"
        
        # Show what changed
        terraform show -no-color tfplan-drift | head -100
        
        # Optionally post to Slack/Teams
        if [ -n "${SLACK_WEBHOOK:-}" ]; then
            curl -X POST -H 'Content-type: application/json' \
                --data "{\"text\":\"🚨 Drift detected in $ENV! Run terraform plan to review.\"}" \
                "$SLACK_WEBHOOK"
        fi
        exit 2
        ;;
esac