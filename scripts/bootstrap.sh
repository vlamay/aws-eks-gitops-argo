#!/bin/bash
# Bootstrap Script for GitOps Platform
# This script automates the complete deployment process

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
AWS_REGION="${AWS_REGION:-us-east-1}"
ENVIRONMENT="${ENVIRONMENT:-dev}"
PROJECT_NAME="${PROJECT_NAME:-gitops}"
TERRAFORM_DIR="terraform/environments/${ENVIRONMENT}"
export TF_DATA_DIR="/tmp/tf_data_${ENVIRONMENT}"
mkdir -p "$TF_DATA_DIR"
ARGOCD_NAMESPACE="argocd"

# Print functions
print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# Check if command exists
check_command() {
    if ! command -v "$1" &> /dev/null; then
        print_error "$1 is not installed"
        return 1
    fi
    print_success "$1 is installed"
    return 0
}

# Check prerequisites
check_prerequisites() {
    print_header "Checking Prerequisites"
    
    local missing=0
    
    check_command "aws" || missing=1
    check_command "terraform" || missing=1
    check_command "kubectl" || missing=1
    check_command "helm" || missing=1
    
    if [ $missing -eq 1 ]; then
        print_error "Missing required tools. Please install them and try again."
        exit 1
    fi
    
    # Check AWS credentials
    print_info "Checking AWS credentials..."
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS credentials not configured. Run 'aws configure' first."
        exit 1
    fi
    print_success "AWS credentials configured"
    
    # Show account info
    ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    print_info "AWS Account ID: $ACCOUNT_ID"
}

# Create Terraform backend resources
create_backend() {
    print_header "Creating Terraform Backend Resources"
    
    local BUCKET_NAME="${PROJECT_NAME}-platform-terraform-state-${ENVIRONMENT}"
    local TABLE_NAME="${PROJECT_NAME}-platform-terraform-locks"
    
    # Create S3 bucket
    print_info "Creating S3 bucket: $BUCKET_NAME"
    if aws s3api head-bucket --bucket "$BUCKET_NAME" 2>/dev/null; then
        print_warning "Bucket already exists"
    else
        aws s3 mb "s3://$BUCKET_NAME" --region "$AWS_REGION"
        
        # Enable versioning
        aws s3api put-bucket-versioning \
            --bucket "$BUCKET_NAME" \
            --versioning-configuration Status=Enabled
        
        # Enable encryption
        aws s3api put-bucket-encryption \
            --bucket "$BUCKET_NAME" \
            --server-side-encryption-configuration '{
                "Rules": [{
                    "ApplyServerSideEncryptionByDefault": {
                        "SSEAlgorithm": "AES256"
                    }
                }]
            }'
        
        # Block public access
        aws s3api put-public-access-block \
            --bucket "$BUCKET_NAME" \
            --public-access-block-configuration \
            "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
        
        print_success "S3 bucket created"
    fi
    
    # Create DynamoDB table
    print_info "Creating DynamoDB table: $TABLE_NAME"
    if aws dynamodb describe-table --table-name "$TABLE_NAME" --region "$AWS_REGION" 2>/dev/null; then
        print_warning "DynamoDB table already exists"
    else
        aws dynamodb create-table \
            --table-name "$TABLE_NAME" \
            --attribute-definitions AttributeName=LockID,AttributeType=S \
            --key-schema AttributeName=LockID,KeyType=HASH \
            --billing-mode PAY_PER_REQUEST \
            --region "$AWS_REGION"
        
        # Wait for table
        aws dynamodb wait table-exists --table-name "$TABLE_NAME" --region "$AWS_REGION"
        print_success "DynamoDB table created"
    fi
}

# Deploy infrastructure with Terraform
deploy_infrastructure() {
    print_header "Deploying Infrastructure with Terraform"
    
    cd "$TERRAFORM_DIR"
    
    # Initialize Terraform
    print_info "Initializing Terraform..."
    terraform init -reconfigure
    print_success "Terraform initialized"
    
    # Plan
    print_info "Running Terraform plan..."
    terraform plan -out=tfplan
    print_success "Terraform plan completed"
    
    # Apply
    print_info "Applying Terraform configuration..."
    print_warning "This will take 15-20 minutes..."
    terraform apply tfplan
    rm -f tfplan
    print_success "Infrastructure deployed"
    
    cd - > /dev/null
}

# Configure kubectl
configure_kubectl() {
    print_header "Configuring kubectl"
    
    local CLUSTER_NAME="${PROJECT_NAME}-${ENVIRONMENT}-cluster"
    
    print_info "Updating kubeconfig..."
    aws eks update-kubeconfig --region "$AWS_REGION" --name "$CLUSTER_NAME"
    print_success "kubectl configured"
    
    # Verify connection
    print_info "Verifying cluster connection..."
    if kubectl cluster-info &> /dev/null; then
        print_success "Connected to cluster"
        echo ""
        kubectl get nodes
    else
        print_error "Failed to connect to cluster"
        exit 1
    fi
}

# Install Argo CD
install_argocd() {
    print_header "Installing Argo CD"
    
    # Run install script
    if [ -f "scripts/install-argocd.sh" ]; then
        chmod +x scripts/install-argocd.sh
        ./scripts/install-argocd.sh
    else
        # Fallback inline installation
        kubectl create namespace "$ARGOCD_NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -
        
        kubectl apply -n "$ARGOCD_NAMESPACE" -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
        
        print_info "Waiting for Argo CD to be ready..."
        kubectl wait --for=condition=available --timeout=300s \
            deployment/argocd-server -n "$ARGOCD_NAMESPACE"
        print_success "Argo CD installed"
    fi
}

# Deploy applications via GitOps
deploy_applications() {
    print_header "Deploying Applications"
    
    # Apply Argo CD configuration
    if [ -f "kubernetes/argocd/argocd-config.yaml" ]; then
        print_info "Applying Argo CD configuration..."
        kubectl apply -f kubernetes/argocd/argocd-config.yaml
        print_success "Argo CD configuration applied"
    fi
    
    # Deploy App of Apps
    if [ -f "argocd-apps/app-of-apps.yaml" ]; then
        print_info "Deploying App of Apps..."
        kubectl apply -f argocd-apps/app-of-apps.yaml
        print_success "App of Apps deployed"
    fi
}

# Get access information
show_access_info() {
    print_header "Access Information"
    
    # Get Argo CD password
    print_info "Argo CD Credentials:"
    echo "  Username: admin"
    echo -n "  Password: "
    kubectl -n "$ARGOCD_NAMESPACE" get secret argocd-initial-admin-secret \
        -o jsonpath="{.data.password}" 2>/dev/null | base64 -d
    echo ""
    
    # Port-forward instructions
    echo ""
    print_info "To access Argo CD UI, run:"
    echo "  kubectl port-forward svc/argocd-server -n argocd 8080:443"
    echo "  Then open: https://localhost:8080"
    
    # Terraform outputs
    echo ""
    print_info "Terraform Outputs:"
    cd "$TERRAFORM_DIR"
    terraform output
    cd - > /dev/null
}

# Cleanup function
cleanup() {
    print_header "Cleaning Up (Ctrl+C to cancel)"
    
    read -p "Are you sure you want to destroy all resources? (yes/no): " confirm
    if [ "$confirm" = "yes" ]; then
        cd "$TERRAFORM_DIR"
        terraform destroy
        cd - > /dev/null
        print_success "Resources destroyed"
    else
        print_info "Cleanup cancelled"
    fi
}

# Main function
main() {
    print_header "GitOps Platform Bootstrap"
    print_info "Environment: $ENVIRONMENT"
    print_info "Region: $AWS_REGION"
    
    case "${1:-}" in
        --cleanup|--destroy)
            cleanup
            exit 0
            ;;
        --argocd-only)
            configure_kubectl
            install_argocd
            deploy_applications
            show_access_info
            exit 0
            ;;
        --skip-terraform)
            configure_kubectl
            install_argocd
            deploy_applications
            show_access_info
            exit 0
            ;;
    esac
    
    # Full deployment
    check_prerequisites
    create_backend
    deploy_infrastructure
    configure_kubectl
    install_argocd
    deploy_applications
    show_access_info
    
    print_header "Deployment Complete!"
    print_success "GitOps platform is ready!"
    echo ""
    print_info "Next steps:"
    echo "  1. Access Argo CD UI to monitor applications"
    echo "  2. Check all applications are synced"
    echo "  3. Access Grafana for monitoring"
    echo ""
    print_warning "Remember to delete resources when not in use to save costs!"
}

# Run main
main "$@"
