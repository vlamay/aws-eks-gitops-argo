variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "gitops"
}

variable "owner" {
  description = "Owner of the resources"
  type        = string
  default     = "platform-team"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "cluster_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.28"
}

variable "public_access_cidrs" {
  description = "CIDR blocks that can access the public API endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"] # Restrict this in production!
}
