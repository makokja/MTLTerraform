output "vpc_id" {
  value = aws_vpc.eks_vpc.id
}

output "subnet_ids" {
  value = [
    aws_subnet.eks_subnet_a.id,
    aws_subnet.eks_subnet_b.id,
  ]
}

output "cluster_name" {
  value = aws_eks_cluster.my_cluster.name
}

output "node_group_name" {
  value = aws_eks_node_group.my_node_group.node_group_name
}

output "node_role_arn" {
  value = aws_eks_node_group.my_node_group.node_role_arn
}

output "eks_sg_id" {
  value = aws_security_group.eks_sg.id
}

output "eks_igw_id" {
  value = aws_internet_gateway.eks_igw.id
}
