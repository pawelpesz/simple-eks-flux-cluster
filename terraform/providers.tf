provider "aws" {
  region = var.region
  #access_key from AWS_ACCESS_KEY_ID
  #secret_key from AWS_SECRET_ACCESS_KEY
  default_tags {
    tags = merge(var.common_tags, {
      Terraform   = true
      Environment = var.environment
    })
  }
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_name
}

# See: https://github.com/terraform-aws-modules/terraform-aws-eks/issues/1280#issuecomment-804499461
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

provider "flux" {
  kubernetes = {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
  git = {
    url = local.github_repo_url
    http = {
      username = var.github_owner
      password = var.github_token
    }
  }
}
