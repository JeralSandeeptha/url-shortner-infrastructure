###############
# EKS Cluster #
###############

# Create Cluster
resource "aws_eks_cluster" "url_shortner_eks_cluster" {
  name = "URL_Shortner_EKS_Cluster"

  access_config {
    authentication_mode = "API"
  }

  role_arn = aws_iam_role.url_shortner_eks_cluster_role.arn
  version  = "1.31"

  vpc_config {
    subnet_ids = [
      aws_subnet.url_shortner_private_subnet_01.id,
      aws_subnet.url_shortner_private_subnet_02.id,
    ]
  }

  # Ensure that IAM Role permissions are created before and deleted
  # after EKS Cluster handling. Otherwise, EKS will not be able to
  # properly delete EKS managed EC2 infrastructure such as Security Groups.
  depends_on = [
    aws_iam_role_policy_attachment.url_shortner_eks_cluster_role_attachment,
  ]
}

# Create IAM Role for EKS Cluster
resource "aws_iam_role" "url_shortner_eks_cluster_role" {
  name = "URL_Shortner_EKS_Cluster_Role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      },
    ]
  })
}

# Attach Policies to EKS Cluster IAM Role
resource "aws_iam_role_policy_attachment" "url_shortner_eks_cluster_role_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.url_shortner_eks_cluster_role.name
}

##############
# Node Group #
##############

# Create Node Group
resource "aws_eks_node_group" "url_shortner_eks_node_group" {
  cluster_name    = aws_eks_cluster.url_shortner_eks_cluster.name
  node_group_name = "URL_Shortner_EKS_Node_Group"
  node_role_arn   = aws_iam_role.url_shortner_eks_node_group_role.arn
  ami_type        = "AL2023_x86_64_STANDARD"
  instance_types  = ["t3.small"]
  subnet_ids = [
    aws_subnet.url_shortner_private_subnet_01.id,
    aws_subnet.url_shortner_private_subnet_02.id,
  ]

  scaling_config {
    desired_size = 1
    max_size     = 2
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_iam_role_policy_attachment.url_shortner_AmazonEC2ContainerRegistryReadOnly,
    aws_iam_role_policy_attachment.url_shortner_AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.url_shortner_AmazonEKSWorkerNodePolicy,
  ]
}

# Create IAM Role for EKS Node Group
resource "aws_iam_role" "url_shortner_eks_node_group_role" {
  name = "URL_Shortner_EKS_Node_Group_Role"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "url_shortner_AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.url_shortner_eks_node_group_role.name
}

resource "aws_iam_role_policy_attachment" "url_shortner_AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.url_shortner_eks_node_group_role.name
}

resource "aws_iam_role_policy_attachment" "url_shortner_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.url_shortner_eks_node_group_role.name
}

# EKS Access Entry and Policy Association for Cluster Admin
resource "aws_eks_access_entry" "cluster_admin" {
  cluster_name  = aws_eks_cluster.url_shortner_eks_cluster.name
  principal_arn = var.eks_admin_principal_arn
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "cluster_admin_policy" {
  cluster_name  = aws_eks_cluster.url_shortner_eks_cluster.name
  principal_arn = aws_eks_access_entry.cluster_admin.principal_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }
}