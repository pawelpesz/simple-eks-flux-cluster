module "s3_loki" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 3.0"

  bucket        = var.loki_s3_bucket_name
  acl           = "private"
  force_destroy = true
}

data "aws_iam_policy_document" "loki_s3_iam_policy" {
  statement {
    actions = [
      "s3:DeleteObject",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:PutObject"
    ]
    resources = [
      module.s3_loki.s3_bucket_arn,
      "${module.s3_loki.s3_bucket_arn}/*"
    ]
  }
}

module "loki_s3_iam_policy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "~> 5.27"

  name_prefix = "${var.cluster_name}-loki-storage-"
  description = "Loki S3 storage policy"
  policy      = data.aws_iam_policy_document.loki_s3_iam_policy.json
}

module "loki_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.27"

  role_name = "${var.cluster_name}-loki-storage"
  role_policy_arns = {
    policy = module.loki_s3_iam_policy.arn
  }

  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["observability:${var.loki_serviceaccount_name}"]
    }
  }
}
