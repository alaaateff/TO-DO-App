module "eks" {
    source = "../modules"
    cidr_block = var.cidr_block
    pub-sub-count = var.pub-sub-count
    pub-sub-cidr = var.pub-sub-cidr
    pub-az = var.pub-az
    priv-sub-count = var.priv-sub-count
    priv-sub-cidr = var.priv-sub-cidr
    priv-az = var.priv-az
    eks-sg = var.eks-sg
    cluster-name = var.cluster-name
    cluster-version = var.cluster-version
    endpoint-private-access = var.endpoint-private-access
    endpoint-public-access = var.endpoint-public-access
    addons = var.addons
    desired_capacity_on_demand = var.desired_capacity_on_demand
    min_capacity_on_demand = var.min_capacity_on_demand
    max_capacity_on_demand = var.max_capacity_on_demand
    ondemand_instance_types = var.ondemand_instance_types
    desired_capacity_spot = var.desired_capacity_spot
    min_capacity_spot = var.min_capacity_spot
    max_capacity_spot = var.max_capacity_spot
    spot_instance_types = var.spot_instance_types 
}

resource "aws_iam_policy" "aws_load_balancer_controller_policy" {
  name        = "aws_load_balancer_controller_policy"
  path        = "/"
  policy = file("../../iam_policy.json")
}

resource "aws_iam_role" "aws_load_balancer_controller_role" {
  name = "aws_load_balancer_controller_role"

  assume_role_policy = jsonencode({
    "Version":"2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "arn:aws:iam::214519213041:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/B16D75C26B69AEC5EF370433C797D9B7"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                    "oidc.eks.us-east-1.amazonaws.com/id/B16D75C26B69AEC5EF370433C797D9B7:aud": "sts.amazonaws.com",
                    "oidc.eks.us-east-1.amazonaws.com/id/B16D75C26B69AEC5EF370433C797D9B7:sub": "system:serviceaccount:kube-system:aws-load-balancer-controller"
                }
            }
        }
    ]
})
}

resource "aws_iam_role_policy_attachment" "aws_load_balancer_controller_attachement" {
  role       = aws_iam_role.aws_load_balancer_controller_role.name
  policy_arn = "arn:aws:iam::214519213041:policy/aws_load_balancer_controller_policy"
}



resource "aws_ecr_repository" "frontend_repo" {
  name = "frontend-repo"
    image_tag_mutability = "IMMUTABLE"
    image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository" "backend_repo" {
  name = "backend-repo"
    image_tag_mutability = "IMMUTABLE"
    image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_kms_key" "kms_key" {
  description             = "KMS key for database credentials rotation"
  enable_key_rotation     = true
  deletion_window_in_days = 7
}

resource "aws_secretsmanager_secret" "db_credentials" {
  name = "database-credentials"
  kms_key_id = aws_kms_key.kms_key.key_id
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "db_credentials_version" {
  secret_id     = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = var.db_username,
    password = var.db_password
  })
}
resource "aws_iam_policy" "external_secrets_policy" {
  name = "external-secrets-policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:ListSecrets"
        ],
        Resource = "arn:aws:secretsmanager:us-east-1:214519213041:secret:database-credentials*"
      },
      {
          Effect = "Allow",
          Action = [
               "kms:Decrypt",
               "kms:DescribeKey"
                ],
          Resource = aws_kms_key.kms_key.arn
}
    ]
  })
}

resource "aws_iam_role" "external_secret_operator_role" {
  name = "external_secret_operator_role"

  assume_role_policy = jsonencode({
    "Version":"2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "arn:aws:iam::214519213041:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/B16D75C26B69AEC5EF370433C797D9B7"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                    "oidc.eks.us-east-1.amazonaws.com/id/B16D75C26B69AEC5EF370433C797D9B7:aud": "sts.amazonaws.com",
                    "oidc.eks.us-east-1.amazonaws.com/id/B16D75C26B69AEC5EF370433C797D9B7:sub": "system:serviceaccount:external-secrets:external-secret-operator"
                }
            }
        }
    ]
})
}

resource "aws_iam_role_policy_attachment" "external_secret_operator_attachement" {
  role       = aws_iam_role.external_secret_operator_role.name
  policy_arn = aws_iam_policy.external_secrets_policy.arn
}

resource "aws_efs_file_system" "efs" {
  creation_token = "my-efs"
  encrypted = true
  tags = {
    Name = "MyEFS"
  }
}

resource "aws_security_group" "efs-sg" {
  name        = "efs-sg"
  description = "Allow 2049 from nodes"
  vpc_id      = module.eks.vpc_id
  tags = {
    Name = "efs_sg"
  }
  ingress {
    from_port = 2049
    to_port = 2049
    protocol = "tcp"
    security_groups = [module.eks.eks_node_sg_id]
    }
  egress {
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
}
}

resource "aws_efs_mount_target" "efs_mount" {
  for_each = {
  for index, subnet_id in module.eks.priv_sub_ids :
  index => subnet_id
}
  file_system_id = aws_efs_file_system.efs.id
  subnet_id      = each.value
  security_groups = [aws_security_group.efs-sg.id]
}

