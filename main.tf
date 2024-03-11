provider "aws" {
  region = var.region
}

resource "aws_vpc" "eks_vpc" {
  cidr_block = var.vpc_cidr_block
  enable_dns_support = true
  enable_dns_hostnames = true
}

resource "aws_subnet" "eks_subnet_a" {
  vpc_id            = aws_vpc.eks_vpc.id
  cidr_block        = var.subnet_cidr_a
  availability_zone = var.availability_zone_a
  map_public_ip_on_launch = true
}

resource "aws_subnet" "eks_subnet_b" {
  vpc_id            = aws_vpc.eks_vpc.id
  cidr_block        = var.subnet_cidr_b
  availability_zone = var.availability_zone_b
  map_public_ip_on_launch = true
}

resource "aws_route_table" "eks_route_table_a" {
  vpc_id = aws_vpc.eks_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.eks_igw.id
  }
}

resource "aws_route_table" "eks_route_table_b" {
  vpc_id = aws_vpc.eks_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.eks_igw.id
  }
}

resource "aws_route_table_association" "eks_association_a" {
  subnet_id      = aws_subnet.eks_subnet_a.id
  route_table_id = aws_route_table.eks_route_table_a.id
}

resource "aws_route_table_association" "eks_association_b" {
  subnet_id      = aws_subnet.eks_subnet_b.id
  route_table_id = aws_route_table.eks_route_table_b.id
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "eks-role" {
  name               = "eks-cluster-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks-role.name
}


resource "aws_eks_cluster" "my_cluster" {
  name     = "MTLTest-cluster"
  role_arn = aws_iam_role.eks-role.arn
  version  = "1.25"

  vpc_config {
    subnet_ids = [
      aws_subnet.eks_subnet_a.id,
      aws_subnet.eks_subnet_b.id,
    ]
    security_group_ids = [aws_security_group.eks_sg.id]
  }
}

resource "aws_eks_node_group" "my_node_group" {
  cluster_name    = aws_eks_cluster.my_cluster.name
  node_group_name = "my-node-group"
  node_role_arn   = aws_iam_role.node_role.arn
  subnet_ids      = [aws_subnet.eks_subnet_a.id, aws_subnet.eks_subnet_b.id]
  scaling_config {
    desired_size = 1
    max_size     = 2
    min_size     = 1
  }
  depends_on = [
    aws_iam_role_policy_attachment.eks_node_group_policy_attachment,
    aws_iam_role_policy_attachment.eks_cni_policy_attachment,
    aws_iam_role_policy_attachment.eks_AmazonEC2ContainerRegistryReadOnly,
  ]
}

resource "aws_iam_role" "node_role" {
  name               = "eks-node-role"
  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_node_group_policy_attachment" {
  role       = aws_iam_role.node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy_attachment" {
  role       = aws_iam_role.node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "eks_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node_role.name
}


resource "aws_security_group" "eks_sg" {
  name   = "eks-sg"
  vpc_id = aws_vpc.eks_vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_internet_gateway" "eks_igw" {
  vpc_id = aws_vpc.eks_vpc.id
}
