# Outputs
output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = module.eks.cluster_security_group_id
}

output "oidc_provider_arn" {
  description = "ARN of the OIDC provider"
  value       = module.eks.oidc_provider_arn
}

output "configure_kubectl" {
  description = "Command to configure kubectl"
  value       = "aws eks update-kubeconfig --region ${var.region} --name ${module.eks.cluster_name}"
}

output "s3_artifacts_bucket" {
  description = "S3 bucket for GitOps artifacts"
  value       = aws_s3_bucket.gitops_artifacts.id
}

output "ecr_ml_models_repository" {
  description = "ECR repository for ML models"
  value       = aws_ecr_repository.ml_models.repository_url
}

output "ecr_applications_repository" {
  description = "ECR repository for applications"
  value       = aws_ecr_repository.applications.repository_url
}

output "aws_lb_controller_role_arn" {
  description = "IAM role ARN for AWS Load Balancer Controller"
  value       = module.aws_load_balancer_controller_irsa.role_arn
}

output "external_dns_role_arn" {
  description = "IAM role ARN for External DNS"
  value       = module.external_dns_irsa.role_arn
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnet_ids
}
