variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version for EKS cluster"
  type        = string
  default     = "1.28"
}

variable "vpc_id" {
  description = "VPC ID where EKS cluster will be deployed"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for EKS worker nodes"
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for EKS load balancers"
  type        = list(string)
}

variable "endpoint_private_access" {
  description = "Enable private API endpoint"
  type        = bool
  default     = true
}

variable "endpoint_public_access" {
  description = "Enable public API endpoint"
  type        = bool
  default     = true
}

variable "public_access_cidrs" {
  description = "List of CIDR blocks that can access the public API endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "cluster_log_types" {
  description = "List of control plane log types to enable"
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 7
}

variable "kms_key_arn" {
  description = "ARN of KMS key for cluster encryption (creates new if empty)"
  type        = string
  default     = ""
}

variable "node_groups" {
  description = "Map of node group configurations"
  type = map(object({
    desired_size    = number
    max_size        = number
    min_size        = number
    max_unavailable = number
    instance_types  = list(string)
    capacity_type   = string
    disk_size       = number
    labels          = map(string)
    taints = list(object({
      key    = string
      value  = string
      effect = string
    }))
    tags = map(string)
  }))
  default = {
    general = {
      desired_size    = 2
      max_size        = 5
      min_size        = 1
      max_unavailable = 1
      instance_types  = ["t3.large"]
      capacity_type   = "ON_DEMAND"
      disk_size       = 50
      labels = {
        workload = "general"
      }
      taints = []
      tags   = {}
    }
  }
}

variable "vpc_cni_version" {
  description = "VPC CNI addon version"
  type        = string
  default     = "v1.15.1-eksbuild.1"
}

variable "coredns_version" {
  description = "CoreDNS addon version"
  type        = string
  default     = "v1.10.1-eksbuild.6"
}

variable "kube_proxy_version" {
  description = "Kube-proxy addon version"
  type        = string
  default     = "v1.28.2-eksbuild.2"
}

variable "ebs_csi_driver_version" {
  description = "EBS CSI driver addon version"
  type        = string
  default     = "v1.25.0-eksbuild.1"
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}
