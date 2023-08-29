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
      # See: https://repost.aws/knowledge-center/eks-configure-sso-user
      rolearn = replace(arn.arn, "/aws-reserved\\/sso\\.amazonaws\\.com\\/([[:alnum:]-]+)\\//", "")
      groups  = ["system:masters"]
    } if startswith(arn.resource, "role/")
  ]
  ami_filters = {
    "AL2_x86_64" = "amazon-eks-node-${var.eks_version}-v*"
    "AL2_ARM_64" = "amazon-eks-arm64-node-${var.eks_version}-v*"
  }
}

data "aws_ami" "eks" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = [local.ami_filters[var.ami_type]]
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.16"

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.intra_subnets

  cluster_name                   = var.cluster_name
  cluster_version                = var.eks_version
  cluster_endpoint_public_access = true

  cluster_enabled_log_types              = var.cluster_enabled_log_types
  create_cloudwatch_log_group            = true
  cloudwatch_log_group_retention_in_days = var.cluster_logs_retention

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
      configuration_values = jsonencode({
        env = {
          ENABLE_PREFIX_DELEGATION = "true"
          WARM_PREFIX_TARGET       = "1"
        }
      })
    }
    aws-ebs-csi-driver = {
      most_recent              = true
      resolve_conflicts        = "PRESERVE"
      service_account_role_arn = module.ebs_csi_irsa_role.iam_role_arn
    }
  }

  # No need to create for EKS-managed node groups
  create_aws_auth_configmap = false
  manage_aws_auth_configmap = true

  aws_auth_users = local.admin_users
  aws_auth_roles = local.admin_roles

  kms_key_administrators = concat(
    [data.aws_iam_session_context.current.issuer_arn],
    var.admin_arns
  )

  node_security_group_additional_rules = {
    ingress_ec2_instance_connect = {
      description              = "Ingress from EC2 Instance Connect VPC Endpoint"
      protocol                 = "tcp"
      from_port                = 22
      to_port                  = 22
      type                     = "ingress"
      source_security_group_id = module.ec2_instance_connect_sg.security_group_id
    }
  }

  eks_managed_node_group_defaults = {
    vpc_security_group_ids = [module.efs.security_group_id]
  }
  eks_managed_node_groups = {
    default = {
      name                            = var.cluster_name
      use_name_prefix                 = true
      launch_template_name            = var.cluster_name
      launch_template_use_name_prefix = true

      min_size     = 1
      max_size     = var.cluster_max_size
      desired_size = 1

      instance_types       = var.instance_types
      capacity_type        = var.use_spot_instances ? "SPOT" : "ON_DEMAND"
      force_update_version = true

      ami_id                     = data.aws_ami.eks.id
      enable_bootstrap_user_data = true
      bootstrap_extra_args       = "--use-max-pods false --kubelet-extra-args '--max-pods=${var.cluster_max_pods}'"
    }
  }
}

module "ebs_csi_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.29"

  role_name_prefix      = "${var.cluster_name}-ebs-csi-"
  attach_ebs_csi_policy = true

  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }
}
