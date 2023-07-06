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

  role_name_prefix      = "efs-csi-"
  attach_efs_csi_policy = true

  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:efs-csi-controller-sa"]
    }
  }
}

resource "helm_release" "efs_csi_driver" {
  name            = "aws-efs-csi-driver"
  repository      = "https://kubernetes-sigs.github.io/aws-efs-csi-driver/"
  chart           = "aws-efs-csi-driver"
  namespace       = "kube-system"
  version         = "2.4.6"
  atomic          = true
  force_update    = true
  cleanup_on_fail = true
  reset_values    = true
  set {
    name  = "controller.serviceAccount.eks\\.amazonaws\\.com/role-arn"
    value = module.efs_csi_irsa_role.iam_role_arn
  }
  set {
    name  = "storageClasses[0].name"
    value = "efs"
  }
  set_list {
    name  = "storageClasses[0].mountOptions"
    value = ["tls"]
  }
  set {
    name  = "storageClasses[0].parameters.provisioningMode"
    value = "efs-ap"
  }
  set {
    name  = "storageClasses[0].parameters.fileSystemId"
    value = module.efs.id
  }
  set {
    name  = "storageClasses[0].parameters.directoryPerms"
    value = "700"
    type  = "string"
  }
  depends_on = [module.eks.cluster_addons]
}
