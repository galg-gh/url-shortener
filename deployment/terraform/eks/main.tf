module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "4.0.0"

  name = "url-app-vpc"
  cidr = "10.0.0.0/16"

  azs             = data.aws_availability_zones.available.names
  private_subnets = ["10.0.0.0/22", "10.0.4.0/22", "10.0.8.0/22"]
  public_subnets  = ["10.0.100.0/22", "10.0.104.0/22", "10.0.108.0/22"]

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }

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
    instance_types             = ["t2.small"]
    iam_role_attach_cni_policy = true
  }

  eks_managed_node_groups = {
    stw_node_wg = {
      min_size     = 1
      max_size     = 1
      desired_size = 1
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

resource "aws_iam_openid_connect_provider" "eks-cluster-oidc" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks-cluster-tls-certificate.certificates[0].sha1_fingerprint]
  url             = module.eks.cluster_oidc_issuer_url
}


resource "aws_iam_policy" "ALBIngressControllerIAMPolicy" {
  name        = "ALBIngressControllerIAMPolicy"
  description = "Policy which will be used by role for service - for creating alb from within cluster by issuing declarative kube commands"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "elasticloadbalancing:ModifyListener",
          "wafv2:AssociateWebACL",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:DescribeInstances",
          "wafv2:GetWebACLForResource",
          "elasticloadbalancing:RegisterTargets",
          "iam:ListServerCertificates",
          "wafv2:GetWebACL",
          "elasticloadbalancing:SetIpAddressType",
          "elasticloadbalancing:DeleteLoadBalancer",
          "elasticloadbalancing:SetWebAcl",
          "ec2:DescribeInternetGateways",
          "elasticloadbalancing:DescribeLoadBalancers",
          "waf-regional:GetWebACLForResource",
          "acm:GetCertificate",
          "shield:DescribeSubscription",
          "waf-regional:GetWebACL",
          "elasticloadbalancing:CreateRule",
          "ec2:DescribeAccountAttributes",
          "elasticloadbalancing:AddListenerCertificates",
          "elasticloadbalancing:ModifyTargetGroupAttributes",
          "waf:GetWebACL",
          "iam:GetServerCertificate",
          "wafv2:DisassociateWebACL",
          "shield:GetSubscriptionState",
          "ec2:CreateTags",
          "elasticloadbalancing:CreateTargetGroup",
          "ec2:ModifyNetworkInterfaceAttribute",
          "elasticloadbalancing:DeregisterTargets",
          "elasticloadbalancing:DescribeLoadBalancerAttributes",
          "ec2:RevokeSecurityGroupIngress",
          "elasticloadbalancing:DescribeTargetGroupAttributes",
          "shield:CreateProtection",
          "acm:DescribeCertificate",
          "elasticloadbalancing:ModifyRule",
          "elasticloadbalancing:AddTags",
          "elasticloadbalancing:DescribeRules",
          "ec2:DescribeSubnets",
          "elasticloadbalancing:ModifyLoadBalancerAttributes",
          "waf-regional:AssociateWebACL",
          "tag:GetResources",
          "ec2:DescribeAddresses",
          "ec2:DeleteTags",
          "shield:DescribeProtection",
          "shield:DeleteProtection",
          "elasticloadbalancing:RemoveListenerCertificates",
          "tag:TagResources",
          "elasticloadbalancing:RemoveTags",
          "elasticloadbalancing:CreateListener",
          "elasticloadbalancing:DescribeListeners",
          "ec2:DescribeNetworkInterfaces",
          "ec2:CreateSecurityGroup",
          "acm:ListCertificates",
          "elasticloadbalancing:DescribeListenerCertificates",
          "ec2:ModifyInstanceAttribute",
          "elasticloadbalancing:DeleteRule",
          "cognito-idp:DescribeUserPoolClient",
          "ec2:DescribeInstanceStatus",
          "elasticloadbalancing:DescribeSSLPolicies",
          "elasticloadbalancing:CreateLoadBalancer",
          "waf-regional:DisassociateWebACL",
          "elasticloadbalancing:DescribeTags",
          "ec2:DescribeTags",
          "elasticloadbalancing:*",
          "elasticloadbalancing:SetSubnets",
          "elasticloadbalancing:DeleteTargetGroup",
          "ec2:DescribeSecurityGroups",
          "iam:CreateServiceLinkedRole",
          "ec2:DescribeVpcs",
          "ec2:DeleteSecurityGroup",
          "elasticloadbalancing:DescribeTargetHealth",
          "elasticloadbalancing:SetSecurityGroups",
          "elasticloadbalancing:DescribeTargetGroups",
          "shield:ListProtections",
          "elasticloadbalancing:ModifyTargetGroup",
          "elasticloadbalancing:DeleteListener"
        ],
        Resource = "*"
      }
    ]
  })
}

# Create IAM role
resource "aws_iam_role" "alb-ingress-controller-role" {
  name = "alb-ingress-controller"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Federated": "${aws_iam_openid_connect_provider.eks-cluster-oidc.arn}"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "${replace(aws_iam_openid_connect_provider.eks-cluster-oidc.url, "https://", "")}:sub": "system:serviceaccount:kube-system:alb-ingress-controller",
          "${replace(aws_iam_openid_connect_provider.eks-cluster-oidc.url, "https://", "")}:aud": "sts.amazonaws.com"
        }
      }
    }
  ]
}
POLICY

  depends_on = [aws_iam_openid_connect_provider.eks-cluster-oidc]

  tags = {
    "ServiceAccountName" = "alb-ingress-controller"
    "ServiceAccountNameSpace" = "kube-system"
  }
}

# Attach policies to IAM role
resource "aws_iam_role_policy_attachment" "alb-ingress-controller-role-ALBIngressControllerIAMPolicy" {
  policy_arn = aws_iam_policy.ALBIngressControllerIAMPolicy.arn
  role       = aws_iam_role.alb-ingress-controller-role.name
  depends_on = [aws_iam_role.alb-ingress-controller-role]
}

resource "aws_iam_role_policy_attachment" "alb-ingress-controller-role-AmazonEKS_CNI_Policy" {
  role       = aws_iam_role.alb-ingress-controller-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  depends_on = [aws_iam_role.alb-ingress-controller-role]
}
