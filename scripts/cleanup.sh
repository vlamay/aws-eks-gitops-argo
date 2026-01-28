#!/bin/bash
# Cleanup Script for GitOps Platform
# Destroys all resources to save costs

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
AWS_REGION="${AWS_REGION:-us-east-1}"
ENVIRONMENT="${ENVIRONMENT:-dev}"
PROJECT_NAME="${PROJECT_NAME:-gitops}"
TERRAFORM_DIR="terraform/environments/${ENVIRONMENT}"

print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

print_header "GitOps Platform Cleanup"

print_warning "This script will DESTROY all resources including:"
echo "  - EKS cluster and all workloads"
echo "  - VPC and networking"
echo "  - S3 buckets"
echo "  - ECR repositories"
echo "  - All data stored in the cluster"
echo ""

read -p "Are you absolutely sure? Type 'yes-destroy-everything' to confirm: " confirm

if [ "$confirm" != "yes-destroy-everything" ]; then
    print_info "Cleanup cancelled"
    exit 0
fi

echo ""
print_info "Starting cleanup..."

# Delete Argo CD applications first
print_info "Removing Argo CD applications..."
kubectl delete -f argocd-apps/ --ignore-not-found=true 2>/dev/null || true

# Wait a bit for resources to be cleaned up
sleep 10

# Delete namespaces
print_info "Removing namespaces..."
kubectl delete namespace argocd monitoring mlops seldon-system --ignore-not-found=true 2>/dev/null || true

# Destroy Terraform resources
print_header "Destroying Terraform Resources"

cd "$TERRAFORM_DIR"

print_warning "Running terraform destroy..."
terraform destroy -auto-approve

cd - > /dev/null

print_success "Infrastructure destroyed"

# Optionally clean up backend
echo ""
read -p "Also delete Terraform state backend (S3 bucket and DynamoDB table)? (yes/no): " confirm_backend

if [ "$confirm_backend" = "yes" ]; then
    BUCKET_NAME="${PROJECT_NAME}-platform-terraform-state-${ENVIRONMENT}"
    TABLE_NAME="${PROJECT_NAME}-platform-terraform-locks"
    
    print_info "Deleting S3 bucket: $BUCKET_NAME"
    aws s3 rb "s3://$BUCKET_NAME" --force 2>/dev/null || print_warning "Bucket not found or already deleted"
    
    print_info "Deleting DynamoDB table: $TABLE_NAME"
    aws dynamodb delete-table --table-name "$TABLE_NAME" --region "$AWS_REGION" 2>/dev/null || print_warning "Table not found or already deleted"
    
    print_success "Backend resources deleted"
fi

print_header "Cleanup Complete!"
print_success "All resources have been destroyed"
echo ""
print_info "Thank you for using GitOps Platform!"
