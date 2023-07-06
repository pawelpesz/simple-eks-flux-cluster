data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  azs              = slice(data.aws_availability_zones.available.names, 0, 3)
  private_subnets  = [for i, az in local.azs : cidrsubnet(var.vpc_cidr, 8, i)]
  public_subnets   = [for i, az in local.azs : cidrsubnet(var.vpc_cidr, 8, i + 100)]
  intra_subnets    = [for i, az in local.azs : cidrsubnet(var.vpc_cidr, 8, i + 200)]
  github_repo_url  = (var.github_repo_url != null) ? var.github_repo_url : "https://github.com/${var.github_owner}/${terraform.workspace}.git"
  flux_target_path = "${var.flux_target_base_path}/${var.environment}"
}
