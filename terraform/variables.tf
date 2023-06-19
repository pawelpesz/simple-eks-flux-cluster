variable "admin_arns" {
  description = "IAM principal ARNs (users or roles) to be granted admin access to cluster and its KMS key"
  type        = list(string)
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
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
