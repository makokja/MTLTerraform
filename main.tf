provider "aws" {
  region = "ap-southeast-1" # Change this to your desired region
}

resource "aws_vpc" "eks_vpc" {
  cidr_block = "172.20.0.0/16" # Change this to your desired CIDR block
  enable_dns_support = true
  enable_dns_hostnames = true
}

resource "aws_subnet" "eks_subnet_a" {
  vpc_id            = aws_vpc.eks_vpc.id
  cidr_block        = "172.20.1.0/24" # Change this to your desired subnet CIDR block for AZ A
  availability_zone = "ap-southeast-1a"  # Change this to your desired AZ

  map_public_ip_on_launch = true # Enable auto-assign public IP addresses
}

resource "aws_subnet" "eks_subnet_b" {
  vpc_id            = aws_vpc.eks_vpc.id
  cidr_block        = "172.20.2.0/24" # Change this to your desired subnet CIDR block for AZ B
  availability_zone = "ap-southeast-1b"  # Change this to your desired AZ

  map_public_ip_on_launch = true # Enable auto-assign public IP addresses
}

resource "aws_route_table" "eks_route_table_a" {
  vpc_id = aws_vpc.eks_vpc.id

  route {
    cidr_block = "0.0.0.0/0" # Assuming this is the CIDR block for your EKS control plane
    gateway_id = aws_internet_gateway.eks_igw.id # Assuming you have an internet gateway attached to your VPC
  }
}

resource "aws_route_table" "eks_route_table_b" {
  vpc_id = aws_vpc.eks_vpc.id

  route {
    cidr_block = "0.0.0.0/0" # Assuming this is the CIDR block for your EKS control plane
    gateway_id = aws_internet_gateway.eks_igw.id # Assuming you have an internet gateway attached to your VPC
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
  version  = "1.25" # Change this to your desired EKS version

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
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }
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


resource "aws_security_group" "eks_sg" {
  name   = "eks-sg"
  vpc_id = aws_vpc.eks_vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  // Add inbound rules as per your requirements
}

resource "aws_internet_gateway" "eks_igw" {
  vpc_id = aws_vpc.eks_vpc.id
}
