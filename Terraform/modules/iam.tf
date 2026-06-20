resource "aws_iam_role" "eks-cluster-iam-role" {
  name = "eks-cluster-iam-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks-cluster-policy" {
  role       = aws_iam_role.eks-cluster-iam-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role" "eks-nodegroup-iam-role" {
  name = "eks-nodegroup-iam-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks-workernode-policy" {
  role       = aws_iam_role.eks-nodegroup-iam-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks-cni-policy" {
  role       = aws_iam_role.eks-nodegroup-iam-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "eks-ecr-policy" {
  role       = aws_iam_role.eks-nodegroup-iam-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "eks-ebscsi-driver-policy" {
  role       = aws_iam_role.ebs_csi_irsa.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

resource "aws_iam_role" "ebs_csi_irsa" {
  name               = "ebs_csi_irsa"
  assume_role_policy = data.aws_iam_policy_document.ebs_assume_role.json
}

resource "aws_iam_policy" "efs_csi_policy" {
  name        = "efs_csi_policy"
  path        = "/"
  policy = file("${path.module}/iam-policy-example.json")
}

resource "aws_iam_role" "efs_csi_role" {
  name = "efs_csi_role"

  assume_role_policy = jsonencode({
    "Version":"2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "arn:aws:iam::214519213041:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/774F0C35FD8C0AD1D4D9EA408B832E21"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                    "oidc.eks.us-east-1.amazonaws.com/id/774F0C35FD8C0AD1D4D9EA408B832E21:aud": "sts.amazonaws.com",
                    "oidc.eks.us-east-1.amazonaws.com/id/774F0C35FD8C0AD1D4D9EA408B832E21:sub": "system:serviceaccount:kube-system:efs-csi-controller-sa"
                }
            }
        }
    ]
})
}

resource "aws_iam_role_policy_attachment" "efs_csi_attachement" {
  role       = aws_iam_role.efs_csi_role.name
  policy_arn = "arn:aws:iam::214519213041:policy/efs_csi_policy"
}

