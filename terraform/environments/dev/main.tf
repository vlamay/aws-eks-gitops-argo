# GitOps Platform - Development Environment
# AWS EKS Cluster with complete GitOps setup

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.24"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Environment = var.environment
      Project     = "gitops-platform"
      ManagedBy   = "terraform"
      Owner       = var.owner
    }
  }
}

# Data sources
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

# Local variables
locals {
  cluster_name = "${var.project_name}-${var.environment}-cluster"

  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }

  azs = slice(data.aws_availability_zones.available.names, 0, 3)
}

# VPC Module
module "vpc" {
  source = "../../modules/vpc"

  cluster_name         = local.cluster_name
  vpc_cidr             = var.vpc_cidr
  region               = var.region
  availability_zones   = local.azs
  enable_nat_gateway   = true
  enable_vpc_endpoints = true

  tags = local.common_tags
}

# EKS Module
module "eks" {
  source = "../../modules/eks"

  cluster_name       = local.cluster_name
  cluster_version    = var.cluster_version
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  public_subnet_ids  = module.vpc.public_subnet_ids

  endpoint_private_access = true
  endpoint_public_access  = true
  public_access_cidrs     = var.public_access_cidrs

  cluster_log_types  = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  log_retention_days = 7

  node_groups = {
    general = {
      desired_size    = 2
      max_size        = 4
      min_size        = 1
      max_unavailable = 1
      instance_types  = ["t3.large"]
      capacity_type   = "ON_DEMAND"
      disk_size       = 50
      labels = {
        workload    = "general"
        environment = var.environment
      }
      taints = []
      tags   = {}
    }

    mlops = {
      desired_size    = 1
      max_size        = 3
      min_size        = 0
      max_unavailable = 1
      instance_types  = ["t3.xlarge"]
      capacity_type   = "SPOT"
      disk_size       = 100
      labels = {
        workload    = "mlops"
        environment = var.environment
      }
      taints = [
        {
          key    = "workload"
          value  = "mlops"
          effect = "NoSchedule"
        }
      ]
      tags = {}
    }
  }

  tags = local.common_tags

  depends_on = [module.vpc]
}

# Kubernetes Provider Configuration
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = [
      "eks",
      "get-token",
      "--cluster-name",
      module.eks.cluster_name,
      "--region",
      var.region
    ]
  }
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args = [
        "eks",
        "get-token",
        "--cluster-name",
        module.eks.cluster_name,
        "--region",
        var.region
      ]
    }
  }
}

# S3 Bucket for GitOps artifacts and backups
resource "aws_s3_bucket" "gitops_artifacts" {
  bucket = "${var.project_name}-${var.environment}-artifacts-${data.aws_caller_identity.current.account_id}"

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-artifacts"
    }
  )
}

resource "aws_s3_bucket_versioning" "gitops_artifacts" {
  bucket = aws_s3_bucket.gitops_artifacts.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "gitops_artifacts" {
  bucket = aws_s3_bucket.gitops_artifacts.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "gitops_artifacts" {
  bucket = aws_s3_bucket.gitops_artifacts.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ECR Repositories for ML models and applications
resource "aws_ecr_repository" "ml_models" {
  name                 = "${var.project_name}/${var.environment}/ml-models"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = local.common_tags
}

resource "aws_ecr_repository" "applications" {
  name                 = "${var.project_name}/${var.environment}/applications"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = local.common_tags
}

# ECR Lifecycle Policy
resource "aws_ecr_lifecycle_policy" "ml_models" {
  repository = aws_ecr_repository.ml_models.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v"]
          countType     = "imageCountMoreThan"
          countNumber   = 10
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Remove untagged images older than 7 days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 7
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

resource "aws_ecr_lifecycle_policy" "applications" {
  repository = aws_ecr_repository.applications.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 20 images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v"]
          countType     = "imageCountMoreThan"
          countNumber   = 20
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Remove untagged images older than 3 days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 3
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# IAM Role for AWS Load Balancer Controller
module "aws_load_balancer_controller_irsa" {
  source = "../../modules/irsa"

  cluster_name         = module.eks.cluster_name
  oidc_provider_arn    = module.eks.oidc_provider_arn
  service_account_name = "aws-load-balancer-controller"
  namespace            = "kube-system"
  role_name            = "${local.cluster_name}-aws-lb-controller"

  policy_arns = [
    aws_iam_policy.aws_load_balancer_controller.arn
  ]

  tags = local.common_tags
}

resource "aws_iam_policy" "aws_load_balancer_controller" {
  name        = "${local.cluster_name}-aws-lb-controller-policy"
  description = "IAM policy for AWS Load Balancer Controller"

  policy = file("${path.module}/policies/aws-load-balancer-controller-policy.json")

  tags = local.common_tags
}

# IAM Role for External DNS
module "external_dns_irsa" {
  source = "../../modules/irsa"

  cluster_name         = module.eks.cluster_name
  oidc_provider_arn    = module.eks.oidc_provider_arn
  service_account_name = "external-dns"
  namespace            = "kube-system"
  role_name            = "${local.cluster_name}-external-dns"

  policy_arns = [
    aws_iam_policy.external_dns.arn
  ]

  tags = local.common_tags
}

resource "aws_iam_policy" "external_dns" {
  name        = "${local.cluster_name}-external-dns-policy"
  description = "IAM policy for External DNS"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "route53:ChangeResourceRecordSets"
        ]
        Resource = "arn:aws:route53:::hostedzone/*"
      },
      {
        Effect = "Allow"
        Action = [
          "route53:ListHostedZones",
          "route53:ListResourceRecordSets"
        ]
        Resource = "*"
      }
    ]
  })

  tags = local.common_tags
}
