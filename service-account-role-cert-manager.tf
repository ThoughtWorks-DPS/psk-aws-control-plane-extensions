module "cert_manager_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.43.0"

  role_path                  = "/PSKRoles/"
  role_name                  = "${var.cluster_name}-cert-manager-sa"
  attach_cert_manager_policy = true

  oidc_providers = {
    main = {
      provider_arn               = data.aws_iam_openid_connect_provider.eks.arn
      namespace_service_accounts = ["cert-manager:cert-manager"]
    }
  }
}