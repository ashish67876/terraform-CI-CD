#!/bin/bash
set -euo pipefail

# Usage: terraform.sh <command> <directory>
# Example: terraform.sh plan live/prod/vpc

COMMAND=${1:-plan}
DIR=${2:-.}
TFVARS=${3:-terraform.tfvars}

cd "$DIR"

echo "Running: terraform $COMMAND in $(pwd)"

case $COMMAND in
    init)
        terraform init -backend=true -input=false
        ;;
    
    validate)
        terraform init -backend=false -input=false
        terraform validate -no-color
        ;;
    
    plan)
        terraform init -backend=true -input=false
        terraform plan -input=false -out=tfplan \
            -var-file="$TFVARS" \
            -compact-warnings
        ;;
    
    apply)
        if [ ! -f "tfplan" ]; then
            echo "ERROR: tfplan file not found. Run plan first."
            exit 1
        fi
        terraform apply -input=false -auto-approve tfplan
        ;;
    
    destroy)
        terraform init -backend=true -input=false
        terraform destroy -var-file="$TFVARS" -auto-approve
        ;;
    
    fmt-check)
        terraform fmt -check -recursive -diff
        ;;
    
    *)
        echo "Unknown command: $COMMAND"
        echo "Usage: init | validate | plan | apply | destroy | fmt-check"
        exit 1
        ;;
esac