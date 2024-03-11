provider "kubernetes" {
  # Point to your EKS cluster's API server endpoint
  host                   = "https://6C5B68E2DAC19C470D3A36AF49D409BC.gr7.ap-southeast-1.eks.amazonaws.com"
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.my_cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.my_cluster.token
}

data "aws_eks_cluster" "my_cluster" {
  name = aws_eks_cluster.my_cluster.name
}

data "aws_eks_cluster_auth" "my_cluster" {
  name = aws_eks_cluster.my_cluster.name
}

resource "aws_iam_openid_connect_provider" "eks_oidc_provider" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["3635c50d67d33b6eb0d78061a30e4980eb03d273"]
  url             = data.aws_eks_cluster.my_cluster.identity[0].oidc[0].issuer
}

resource "aws_iam_policy" "eks_app_policy" {
  name        = "eks-app-policy"
  description = "IAM policy for EKS application access to S3 and SQS"
  
  # Define the policy document here with necessary permissions for S3 and SQS
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject"
      ],
      "Resource": "arn:aws:s3:::my-web-assets"
    },
    {
      "Effect": "Allow",
      "Action": [
        "sqs:SendMessage",
        "sqs:ReceiveMessage",
        "sqs:DeleteMessage"
      ],
      "Resource": "arn:aws:sqs:ap-southeast-1:123456789123:lms-import-data"
    }
  ]
}
EOF
}

resource "aws_iam_role" "eks_app_role" {
  name               = "eks-app-role"
  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Principal": {
        "Federated": aws_iam_openid_connect_provider.eks_oidc_provider.arn
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "${aws_iam_openid_connect_provider.eks_oidc_provider.url}:sub": "system:serviceaccount:default:eks-app-service-account"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_app_policy_attachment" {
  role       = aws_iam_role.eks_app_role.name
  policy_arn = aws_iam_policy.eks_app_policy.arn
}

resource "kubernetes_service_account" "eks_app_service_account" {
  metadata {
    name      = "eks-app-service-account"
    namespace = "default"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.eks_app_role.arn
    }
  }
}
