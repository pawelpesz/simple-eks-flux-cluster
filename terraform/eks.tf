data "aws_caller_identity" "current" {}

# See: https://github.com/terraform-aws-modules/terraform-aws-eks/blob/0a17f655fb7da00640627ed9255f1d96e42fcfd7/main.tf#LL4C1-L10C2
data "aws_iam_session_context" "current" {
  arn = data.aws_caller_identity.current.arn
}

locals {
  admin_users = [
    for i, arn in var.admin_arns : {
      username = "user${i}"
      userarn  = arn
      groups   = ["system:masters"]
    }
  ]
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.15"

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.intra_subnets

  cluster_name                   = var.cluster_name
  cluster_version                = var.eks_version
  cluster_endpoint_public_access = true

  cluster_addons = {
    coredns = {
      most_recent       = true
      resolve_conflicts = "OVERWRITE"
    }
    kube-proxy = {
      most_recent       = true
      resolve_conflicts = "OVERWRITE"
    }
    vpc-cni = {
      most_recent       = true
      resolve_conflicts = "OVERWRITE"
    }
  }

  create_aws_auth_configmap = true
  manage_aws_auth_configmap = true

  aws_auth_users = local.admin_users
  kms_key_administrators = concat(
    [data.aws_iam_session_context.current.issuer_arn],
    [for user in local.admin_users : user.userarn]
  )

  eks_managed_node_groups = {
    default = {
      name                            = var.cluster_name
      use_name_prefix                 = true
      launch_template_name            = var.cluster_name
      launch_template_use_name_prefix = true

      min_size     = 1
      max_size     = var.cluster_max_size
      desired_size = 1

      ami_type             = var.ami_type
      instance_types       = var.instance_types
      capacity_type        = var.use_spot_instances ? "SPOT" : "ON_DEMAND"
      force_update_version = true
    }
  }
}
