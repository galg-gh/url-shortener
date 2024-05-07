locals {
  vpc_id              = module.vpc.vpc_id
  vpc_cidr            = module.vpc.vpc_cidr_block
  public_subnets_ids  = module.vpc.public_subnets
  private_subnets_ids = module.vpc.private_subnets
  subnets_ids         = concat(local.public_subnets_ids, local.private_subnets_ids)
}


locals {
  account_id = data.aws_caller_identity.current.account_id
  eks_oidc = replace(replace(module.eks.cluster_endpoint, "https://", ""), "/\\..*$/", "")
}