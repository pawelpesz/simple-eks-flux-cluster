terraform {
  required_version = "~> 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.14"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    flux = {
      source  = "fluxcd/flux"
      version = "~> 1.1"
    }
  }
  cloud {
    # organization from TF_CLOUD_ORGANIZATION
    workspaces {
      name = "simple-eks-flux-cluster"
    }
  }
}
