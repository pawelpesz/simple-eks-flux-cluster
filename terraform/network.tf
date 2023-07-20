module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.1"

  name = "${var.cluster_name}-vpc"
  cidr = var.vpc_cidr

  azs             = data.aws_availability_zones.available.names
  private_subnets = local.private_subnets
  public_subnets  = local.public_subnets
  intra_subnets   = local.intra_subnets

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  # See https://aws.amazon.com/premiumsupport/knowledge-center/eks-vpc-subnet-discovery/
  public_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                    = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"           = "1"
  }
}

module "vpc_endpoints" {
  source  = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  version = "~> 5.1"

  vpc_id = module.vpc.vpc_id

  create_security_group      = true
  security_group_name        = "${var.cluster_name}-vpc-endpoints"
  security_group_description = "VPC Endpoints security group"
  security_group_rules = {
    ingress_https = {
      description = "HTTPS from VPC"
      cidr_blocks = [module.vpc.vpc_cidr_block]
    }
  }

  # See: https://docs.aws.amazon.com/eks/latest/userguide/private-clusters.html
  endpoints = {
    s3 = {
      service = "s3"
      tags    = { Name = "${var.cluster_name}-s3" }
    }
    ec2 = {
      service             = "ec2"
      private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
      tags                = { Name = "${var.cluster_name}-ec2" }
    }
    ecr_api = {
      service             = "ecr.api"
      private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
      tags                = { Name = "${var.cluster_name}-ecr-api" }
    }
    ecr_dkr = {
      service             = "ecr.dkr"
      private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
      tags                = { Name = "${var.cluster_name}-ecr-dkr" }
    }
    elasticloadbalancing = {
      service             = "elasticloadbalancing"
      private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
      tags                = { Name = "${var.cluster_name}-elasticloadbalancing" }
    }
    logs = {
      service             = "logs"
      private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
      tags                = { Name = "${var.cluster_name}-logs" }
    }
    sts = {
      service             = "sts"
      private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
      tags                = { Name = "${var.cluster_name}-sts" }
    }
    kms = {
      service             = "kms"
      private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
      tags                = { Name = "${var.cluster_name}-kms" }
    }
  }
}

module "ec2_instance_connect_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name            = "${var.cluster_name}-ec2-instance-connect"
  use_name_prefix = false
  description     = "Allow traffic from EC2 Instance Connect VPC Endpoint to VPC"
  vpc_id          = module.vpc.vpc_id

  egress_rules       = ["all-tcp"]
  egress_cidr_blocks = [module.vpc.vpc_cidr_block]
}

resource "aws_ec2_instance_connect_endpoint" "endpoint" {
  subnet_id          = module.vpc.private_subnets[0]
  preserve_client_ip = true
  security_group_ids = [module.ec2_instance_connect_sg.security_group_id]
  tags = {
    Name = "${var.cluster_name}-ec2-instance-connect"
  }
}
