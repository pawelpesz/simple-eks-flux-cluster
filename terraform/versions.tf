terraform {
  required_version = "~> 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.4"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.21"
    }
  }
  cloud {
    # organization from TF_CLOUD_ORGANIZATION
    workspaces {
      name = "simple-eks-flux-cluster"
    }
  }
}
