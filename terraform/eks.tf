data "aws_caller_identity" "current" {}

# See: https://github.com/terraform-aws-modules/terraform-aws-eks/blob/0a17f655fb7da00640627ed9255f1d96e42fcfd7/main.tf#LL4C1-L10C2
data "aws_iam_session_context" "current" {
  arn = data.aws_caller_identity.current.arn
}

data "aws_arn" "admin_arns" {
  for_each = toset(var.admin_arns)
  arn      = each.key
}

locals {
  admin_users = [
    for arn in data.aws_arn.admin_arns : {
      username = "user${index(var.admin_arns, arn.arn)}"
      userarn  = arn.arn
      groups   = ["system:masters"]
    } if startswith(arn.resource, "user/")
  ]
  admin_roles = [
    for arn in data.aws_arn.admin_arns : {
      username = "role${index(var.admin_arns, arn.arn)}"
      rolearn  = arn.arn
      groups   = ["system:masters"]
    } if startswith(arn.resource, "role/")
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

  # No need to create for EKS-managed node groups
  create_aws_auth_configmap = false
  manage_aws_auth_configmap = true

  aws_auth_users = local.admin_users
  aws_auth_roles = local.admin_roles

  kms_key_administrators = concat(
    [data.aws_iam_session_context.current.issuer_arn],
    [for user in local.admin_users : user.userarn],
    [for role in local.admin_roles : role.rolearn]
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
