#!/bin/bash
set -euo pipefail

DIR=${1:-.}
BUDGET_THRESHOLD=${2:-500}  # USD

cd "$DIR"

# Check if infracost is installed
if ! command -v infracost &> /dev/null; then
    echo "Infracost not installed, skipping cost check"
    exit 0
fi

echo "Running cost estimation for $DIR"

infracost breakdown --path . \
    --format json \
    --out-file /tmp/infracost.json \
    --terraform-var-file terraform.tfvars

# Extract total monthly cost
MONTHLY_COST=$(cat /tmp/infracost.json | jq -r '.totalMonthlyCost // 0')

echo "Estimated monthly cost: $MONTHLY_COST USD"

# Check against budget
if (( $(echo "$MONTHLY_COST > $BUDGET_THRESHOLD" | bc -l) )); then
    echo "ERROR: Cost $MONTHLY_COST exceeds budget threshold $BUDGET_THRESHOLD"
    exit 1
fi

# Generate diff if baseline exists
if [ -f "infracost-base.json" ]; then
    infracost diff --path /tmp/infracost.json \
        --compare-to infracost-base.json \
        --format table
fi
