#!/bin/bash
# Setup Kubeconfig Script
# Configures kubectl to access the EKS cluster

set -e

# Configuration
AWS_REGION="${AWS_REGION:-us-east-1}"
ENVIRONMENT="${ENVIRONMENT:-dev}"
PROJECT_NAME="${PROJECT_NAME:-gitops}"
CLUSTER_NAME="${PROJECT_NAME}-${ENVIRONMENT}-cluster"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}Configuring kubectl for cluster: ${CLUSTER_NAME}${NC}"

# Check AWS identity
if ! aws sts get-caller-identity &> /dev/null; then
    echo -e "${RED}Error: AWS credentials not configured.${NC}"
    echo "Run 'aws configure' first."
    exit 1
fi

# Update kubeconfig
echo -e "${BLUE}Updating kubeconfig...${NC}"
aws eks update-kubeconfig --region "$AWS_REGION" --name "$CLUSTER_NAME"

# Verify connection
echo -e "${BLUE}Verifying connection...${NC}"
if kubectl cluster-info &> /dev/null; then
    echo -e "${GREEN}Success! Connected to ${CLUSTER_NAME}${NC}"
    echo ""
    echo "Cluster info:"
    kubectl cluster-info
    echo ""
    echo "Nodes:"
    kubectl get nodes
else
    echo -e "${RED}Error: Failed to connect to cluster.${NC}"
    exit 1
fi
