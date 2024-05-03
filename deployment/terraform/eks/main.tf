module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "4.0.0"

  name = "stw-vpc"
  cidr = "10.0.0.0/16"

  azs             = data.aws_availability_zones.available.names
  private_subnets = ["10.0.0.0/22", "10.0.4.0/22", "10.0.8.0/22"]
  public_subnets  = ["10.0.100.0/22", "10.0.104.0/22", "10.0.108.0/22"]

  enable_nat_gateway = true
  single_nat_gateway = true
  enable_vpn_gateway = false

}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name    = "url-app-cluster"
  cluster_version = "1.24"

  cluster_endpoint_public_access = true

  cluster_addons = {
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent              = true
      before_compute           = true
      service_account_role_arn = module.vpc_cni_irsa.iam_role_arn
      configuration_values = jsonencode({
        env = {
          # Reference docs https://docs.aws.amazon.com/eks/latest/userguide/cni-increase-ip-addresses.html
          ENABLE_PREFIX_DELEGATION = "true"
          WARM_PREFIX_TARGET       = "1"
        }
      })
    }
  }

  vpc_id                   = local.vpc_id
  subnet_ids               = local.private_subnets_ids
  control_plane_subnet_ids = local.private_subnets_ids

  # EKS Managed Node Group(s)
  eks_managed_node_group_defaults = {
    ami_type                   = "AL2_x86_64"
    instance_types             = ["t2.micro"]
    iam_role_attach_cni_policy = true
  }

  eks_managed_node_groups = {
    stw_node_wg = {
      min_size     = 2
      max_size     = 2
      desired_size = 2
    }
  }

}

module "vpc_cni_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name_prefix      = "VPC-CNI-IRSA"
  attach_vpc_cni_policy = true
  vpc_cni_enable_ipv4   = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-node"]
    }
  }
}

