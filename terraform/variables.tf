variable "region" {
  description = "AWS region"
  type        = string
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}

variable "environment" {
  description = "Environment type (one of: dev, stage, prod)"
  type        = string
  default     = "dev"
  validation {
    condition     = contains(["dev", "stage", "prod"], var.environment)
    error_message = "Incorrect environment type."
  }
}

variable "vpc_cidr" {
  description = "VPC CIDR"
  type        = string
  default     = "172.72.0.0/16"
}

variable "cluster_name" {
  description = "Cluster name"
  type        = string
  default     = "simple-cluster"
}

variable "eks_version" {
  description = "EKS version"
  type        = string
  default     = "1.27"
}

# See: https://docs.aws.amazon.com/eks/latest/APIReference/API_Nodegroup.html#AmazonEKS-Type-Nodegroup-amiType
variable "ami_type" {
  description = "AMI type for node instances (should be aligned with `instance_types`)"
  type        = string
  default     = "AL2_ARM_64"
}

variable "instance_types" {
  description = "Node instance types (should be aligned with `ami_type`)"
  type        = list(string)
  default     = ["t4g.medium"]
}

variable "use_spot_instances" {
  description = "Whether to use spot instances instead of on-demand ones"
  type        = bool
  default     = false
}

variable "cluster_max_size" {
  description = "Maximium number of node instances"
  type        = number
  default     = 1
}

variable "admin_arns" {
  description = "IAM principal ARNs (users or roles) to be granted admin access to cluster and its KMS key"
  type        = list(string)
}

variable "github_owner" {
  description = "GitHub repository owner"
  type        = string
}

variable "github_token" {
  description = "GitHub fine-grained token with read access to metadata and *read/write* access to code"
  type        = string
  sensitive   = true
}

variable "github_repo_url" {
  description = "Overwrite the repository URL (otherwise it will be calculated using the GH owner and Terraform workspace)"
  type        = string
  default     = null
}

variable "flux_target_base_path" {
  description = "Base path for Flux (environment will be appended to it)"
  type        = string
  default     = "clusters"
}

variable "flux_version" {
  description = "Flux version"
  type        = string
  default     = "v2.0.0-rc.5"
}

variable "flux_components_extra" {
  description = "Flux extra toolkit components to bootstrap"
  type        = set(string)
  default = [
    "image-reflector-controller",
    "image-automation-controller"
  ]
}

variable "flux_interval" {
  description = "Interval at which to reconcile from Flux bootstrap repository"
  type        = string
  default     = "1m0s"
}

variable "flux_log_level" {
  description = "Log level for Flux toolkit components"
  type        = string
  default     = "info"
}
