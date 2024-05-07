data "aws_availability_zones" "available" {
  state = "available"
}

data "tls_certificate" "eks-cluster-tls-certificate" {
  url = module.eks.cluster_oidc_issuer_url
}

data "aws_caller_identity" "current" {}



