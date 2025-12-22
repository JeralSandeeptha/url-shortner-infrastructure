output "vpc_name" {
  value       = "vpc name is ${aws_vpc.url_shortner_vpc.tags["Name"]}"
  description = "This is the name of the VPC"
}

output "vpc_region" {
  value       = "vpc created in ${aws_vpc.url_shortner_vpc.region}"
  description = "Region where the VPC is created"
}

output "vpc_cidr_block" {
  value       = "CIDR Block of the VPC is ${aws_vpc.url_shortner_vpc.cidr_block}"
  description = "CIDR Block of the VPC"
}

output "public_subnet_ids" {
  value       = [aws_subnet.url_shortner_public_subnet_01.id, aws_subnet.url_shortner_public_subnet_02.id]
  description = "List of Public Subnet IDs"
}

output "private_subnet_ids" {
  value       = [aws_subnet.url_shortner_private_subnet_01.id, aws_subnet.url_shortner_private_subnet_02.id]
  description = "List of Public Subnet IDs"
}

output "cluster_name" {
  value       = aws_eks_cluster.url_shortner_eks_cluster.name
  description = "Name of the EKS cluster"
}

output "node_group_name" {
  value       = aws_eks_node_group.url_shortner_eks_node_group.node_group_name
  description = "Name of the EKS node group"
}