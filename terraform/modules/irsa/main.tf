# IRSA (IAM Roles for Service Accounts) Module
# Enables Kubernetes service accounts to assume IAM roles

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Extract OIDC provider URL
locals {
  oidc_provider_url = replace(var.oidc_provider_arn, "/^(.*provider/)/", "")
}

# IAM Role for Service Account
resource "aws_iam_role" "this" {
  name        = var.role_name
  description = var.role_description

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = var.oidc_provider_arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${local.oidc_provider_url}:sub" = "system:serviceaccount:${var.namespace}:${var.service_account_name}"
          "${local.oidc_provider_url}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })

  tags = var.tags
}

# Attach policies to role
resource "aws_iam_role_policy_attachment" "this" {
  count = length(var.policy_arns)

  role       = aws_iam_role.this.name
  policy_arn = var.policy_arns[count.index]
}

# Inline policy if provided
resource "aws_iam_role_policy" "inline" {
  count = var.inline_policy != "" ? 1 : 0

  name   = "${var.role_name}-inline-policy"
  role   = aws_iam_role.this.name
  policy = var.inline_policy
}
