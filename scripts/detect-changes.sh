#!/bin/bash
set -euo pipefail

# Usage: detect-changes.sh <base_ref>
# Example: detect-changes.sh main

BASE_REF=${1:-main}
OUTPUT_FILE=${GITHUB_OUTPUT:-/dev/stdout}

echo "Detecting changes against base: $BASE_REF"

# Get changed files between base and HEAD
CHANGED_FILES=$(git diff --name-only origin/$BASE_REF...HEAD || git diff --name-only $BASE_REF...HEAD)

if [ -z "$CHANGED_FILES" ]; then
    echo "No files changed"
    echo "matrix=[]" >> $OUTPUT_FILE
    exit 0
fi

# Extract unique live environment directories
LIVE_DIRS=$(echo "$CHANGED_FILES" | grep -E '^live/' | awk -F'/' '{print $1"/"$2"/"$3}' | sort -u)

# Extract unique module directories (if modules changed, validate all consumers)
MODULE_DIRS=$(echo "$CHANGED_FILES" | grep -E '^modules/' | awk -F'/' '{print $1"/"$2}' | sort -u)

# If modules changed, we need to test them + all environments that use them
if [ -n "$MODULE_DIRS" ]; then
    echo "Module changes detected: $MODULE_DIRS"
    # Find which live directories reference changed modules
    for module in $MODULE_DIRS; do
        module_name=$(basename $module)
        # Search for module references in live configs
        found_dirs=$(grep -rl "source.*$module_name" live/ 2>/dev/null | awk -F'/' '{print $1"/"$2"/"$3}' | sort -u || true)
        LIVE_DIRS=$(echo -e "$LIVE_DIRS\n$found_dirs" | sort -u)
    done
fi

# Build JSON matrix
MATRIX_JSON=$(echo "$LIVE_DIRS" | grep -v '^$' | jq -R -s -c 'split("\n") | map(select(length > 0))')

echo "Changed directories: $MATRIX_JSON"
echo "matrix=$MATRIX_JSON" >> $OUTPUT_FILE