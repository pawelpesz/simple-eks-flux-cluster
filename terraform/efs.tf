module "efs" {
  source  = "terraform-aws-modules/efs/aws"
  version = "~> 1.2"

  name           = "${var.cluster_name}-pv"
  creation_token = "${var.cluster_name}-pv-token"
  encrypted      = true

  lifecycle_policy = {
    transition_to_ia                    = "AFTER_30_DAYS"
    transition_to_primary_storage_class = "AFTER_1_ACCESS"
  }

  mount_targets         = { for k, v in zipmap(local.azs, module.vpc.private_subnets) : k => { subnet_id = v } }
  security_group_vpc_id = module.vpc.vpc_id
  security_group_rules = {
    vpc = {
      # Relying on the defaults provided for EFS/NFS (2049/TCP + ingress)
      description = "NFS ingress from VPC private subnets"
      cidr_blocks = module.vpc.private_subnets_cidr_blocks
    }
  }
}

module "efs_csi_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.27"

  role_name             = var.efs_csi_irsa_role_name
  attach_efs_csi_policy = true

  oidc_providers = {
    ex = {
      provider_arn = module.eks.oidc_provider_arn
      namespace_service_accounts = [
        "kube-system:efs-csi-controller-sa",
        "kube-system:efs-csi-node-sa"
      ]
    }
  }
}

resource "kubernetes_storage_class_v1" "efs" {
  metadata {
    name = "efs"
  }
  storage_provisioner = "efs.csi.aws.com"
  parameters = {
    provisioningMode = "efs-ap"
    fileSystemId     = module.efs.id
    directoryPerms   = "700"
  }
  depends_on = [flux_bootstrap_git.flux]
}
