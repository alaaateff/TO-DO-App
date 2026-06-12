data "tls_certificate" "eks-certificate" {
  url = aws_eks_cluster.eks.identity[0].oidc[0].issuer
}
data "aws_iam_policy_document" "eks-oidc-assume_role_policy" {

  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks_oidc.url,"https://", "")}:sub"
      values = ["system:serviceaccount:default:aws-test"]
    }

    principals {
        identifiers = [ aws_iam_openid_connect_provider.eks_oidc.arn]
        type = "Federated"
    }
  }
}