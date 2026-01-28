# Deployment Guide - GitOps Platform

## Overview

This guide provides step-by-step instructions for deploying the GitOps platform on AWS EKS.

## Prerequisites

### Required Tools

Install the following tools before proceeding:

```bash
# macOS
brew install awscli terraform kubectl helm

# Linux (Ubuntu/Debian)
# See installation commands in the main README
```

**Version Requirements**:
- AWS CLI >= 2.0
- Terraform >= 1.6.0
- kubectl >= 1.28
- helm >= 3.12

### AWS Requirements

- AWS Account with admin access
- AWS CLI configured with credentials
- Sufficient AWS service limits for:
  - VPCs (1)
  - EKS clusters (1)
  - EC2 instances (3-7 depending on node groups)
  - Elastic IPs (3 for NAT Gateways)
  - Load Balancers (2-3)

### Verify Prerequisites

```bash
# Check AWS access
aws sts get-caller-identity

# Check tool versions
terraform version
kubectl version --client
helm version
```

## Step 1: Clone and Configure

### Clone Repository

```bash
git clone <your-repo-url>
cd gitops-platform
```

### Configure Variables

```bash
cd terraform/environments/dev

# Copy example variables
cp terraform.tfvars.example terraform.tfvars

# Edit with your values
nano terraform.tfvars
```

**Important settings to change**:
```hcl
owner = "your-name"              # Your name
public_access_cidrs = ["YOUR_IP/32"]  # Your IP address
```

Get your IP address:
```bash
curl ifconfig.me
```

## Step 2: Set Up Terraform Backend

The Terraform state will be stored in S3 for team collaboration and safety.

### Create S3 Bucket and DynamoDB Table

```bash
# Set variables
export AWS_REGION="us-east-1"
export ENVIRONMENT="dev"
export ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Create S3 bucket for state
aws s3 mb s3://gitops-platform-terraform-state-${ENVIRONMENT} --region ${AWS_REGION}

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket gitops-platform-terraform-state-${ENVIRONMENT} \
  --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption \
  --bucket gitops-platform-terraform-state-${ENVIRONMENT} \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'

# Block public access
aws s3api put-public-access-block \
  --bucket gitops-platform-terraform-state-${ENVIRONMENT} \
  --public-access-block-configuration \
  "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

# Create DynamoDB table for state locking
aws dynamodb create-table \
  --table-name gitops-platform-terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region ${AWS_REGION}

# Wait for table to be ready
aws dynamodb wait table-exists \
  --table-name gitops-platform-terraform-locks \
  --region ${AWS_REGION}
```

## Step 3: Deploy Infrastructure

### Initialize Terraform

```bash
cd terraform/environments/dev
terraform init
```

You should see:
```
Terraform has been successfully initialized!
```

### Review the Plan

```bash
terraform plan
```

Review the output carefully. You should see resources being created:
- VPC with subnets
- NAT Gateways
- EKS cluster
- Node groups
- IAM roles
- S3 buckets
- ECR repositories

### Apply the Configuration

```bash
terraform apply
```

Type `yes` when prompted.

**Deployment time**: 15-20 minutes

The EKS cluster creation takes the longest (~10-15 minutes).

### Save Outputs

```bash
terraform output > outputs.txt
```

## Step 4: Configure kubectl

### Update kubeconfig

```bash
# Get the command from Terraform output
terraform output -raw configure_kubectl

# Or run directly
aws eks update-kubeconfig --region us-east-1 --name gitops-dev-cluster
```

### Verify Cluster Access

```bash
# Check cluster info
kubectl cluster-info

# List nodes
kubectl get nodes

# You should see 3 nodes (2 general + 1 mlops)
```

Expected output:
```
NAME                          STATUS   ROLES    AGE   VERSION
ip-10-0-11-xxx.ec2.internal   Ready    <none>   5m    v1.28.x
ip-10-0-12-xxx.ec2.internal   Ready    <none>   5m    v1.28.x
ip-10-0-13-xxx.ec2.internal   Ready    <none>   5m    v1.28.x
```

## Step 5: Verify Deployment

### Check EKS Add-ons

```bash
kubectl get pods -n kube-system
```

You should see:
- `coredns-*` pods
- `aws-node-*` pods (VPC CNI)
- `kube-proxy-*` pods
- `ebs-csi-*` pods

### Check Node Groups

```bash
kubectl get nodes --show-labels | grep workload
```

You should see labels:
- `workload=general` on 2 nodes
- `workload=mlops` on 1 node

### Test IRSA Roles

```bash
# Check if OIDC provider exists
aws iam list-open-id-connect-providers | grep $(terraform output -raw oidc_provider_arn | cut -d'/' -f4)
```

## Step 6: Deploy Core Applications (Optional)

At this point, you have a working EKS cluster. To deploy applications via GitOps:

### Install Argo CD

```bash
# Create namespace
kubectl create namespace argocd

# Install Argo CD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for Argo CD to be ready
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd
```

### Access Argo CD

```bash
# Get initial password
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d

# Port-forward to access UI
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Open in browser
open https://localhost:8080
# Username: admin
# Password: <from above command>
```

## Troubleshooting

### Issue: Terraform Init Fails

**Error**: Backend configuration error

**Solution**:
```bash
# Ensure S3 bucket exists
aws s3 ls s3://gitops-platform-terraform-state-dev

# If not, create it (see Step 2)
```

### Issue: EKS Cluster Creation Fails

**Error**: Insufficient capacity or service limits

**Solution**:
```bash
# Check service quotas
aws service-quotas list-service-quotas \
  --service-code eks \
  --query 'Quotas[*].[QuotaName,Value]' \
  --output table

# Request quota increase if needed
```

### Issue: Cannot Access Cluster

**Error**: `error: You must be logged in to the server (Unauthorized)`

**Solution**:
```bash
# Update kubeconfig
aws eks update-kubeconfig --region us-east-1 --name gitops-dev-cluster

# Verify AWS credentials
aws sts get-caller-identity
```

### Issue: Nodes Not Ready

**Error**: Nodes stuck in NotReady state

**Solution**:
```bash
# Check node status
kubectl describe nodes

# Check VPC CNI pods
kubectl get pods -n kube-system -l k8s-app=aws-node

# Restart VPC CNI if needed
kubectl rollout restart daemonset aws-node -n kube-system
```

## Cost Management

### Daily Costs (Approximate)

- EKS Control Plane: $2.40/day ($73/month)
- EC2 Instances (3x t3.large/xlarge): $4-6/day
- NAT Gateways (3x): $2.20/day
- EBS Volumes: $0.30/day
- **Total**: ~$9-11/day (~$270-330/month)

### Cost Optimization Tips

1. **Use Spot Instances** (already configured for mlops node group)
2. **Reduce NAT Gateways**:
   ```hcl
   # In terraform.tfvars
   # Use single NAT for dev (edit VPC module)
   ```
3. **Stop When Not in Use**:
   ```bash
   # Scale down node groups
   aws eks update-nodegroup-config \
     --cluster-name gitops-dev-cluster \
     --nodegroup-name general \
     --scaling-config minSize=0,maxSize=4,desiredSize=0
   ```
4. **Delete When Done**:
   ```bash
   terraform destroy
   ```

## Cleanup

### Destroy Infrastructure

```bash
cd terraform/environments/dev

# Destroy all resources
terraform destroy

# Type 'yes' when prompted
```

**Important**: This will delete:
- EKS cluster and all workloads
- VPC and networking
- S3 buckets (if empty)
- ECR repositories
- All data

### Clean Up Backend (Optional)

```bash
# Delete S3 bucket
aws s3 rb s3://gitops-platform-terraform-state-dev --force

# Delete DynamoDB table
aws dynamodb delete-table --table-name gitops-platform-terraform-locks
```

## Next Steps

After successful deployment:

1. **Deploy Applications**: Use Argo CD to deploy applications
2. **Set Up Monitoring**: Deploy Prometheus and Grafana
3. **Configure DNS**: Set up External DNS with Route53
4. **Add TLS**: Configure cert-manager for SSL certificates
5. **Deploy ML Workloads**: Use the mlops node group

## Support

For issues:
- Check the [Troubleshooting](#troubleshooting) section
- Review Terraform logs
- Check AWS CloudWatch logs
- Open an issue in the repository

---

**Congratulations!** You now have a production-ready EKS cluster with GitOps capabilities! 🎉
