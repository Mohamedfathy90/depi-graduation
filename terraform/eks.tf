# --------------------------------
# Creating Cluster (Control Plane)
# --------------------------------

resource "aws_eks_cluster" "cluster" {
  name     = "${var.project_name}"
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    subnet_ids = aws_subnet.public[*].id
    security_group_ids = [aws_security_group.eks_control_plane.id]
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_AmazonEKSClusterPolicy
  ]
}

# -----------------------------------
# Creating Jenkins Node group
# -----------------------------------

resource "aws_eks_node_group" "jenkins" {
  cluster_name    = aws_eks_cluster.cluster.name
  node_group_name = "${var.project_name}-ng-jenkins"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = [aws_subnet.public[0].id]
  scaling_config {
    desired_size = var.desired_capacity
    max_size     = 2
    min_size     = 1
  }

  instance_types = [var.node_instance_type]
  ami_type       = var.node_ami_type

  labels = {
    role = "jenkins-ng"
  }

  tags = {
    Name = "${var.project_name}-ng-jenkins"
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_AmazonEKSWorkerNodePolicy
  ]
}

# -----------------------------------
# Creating App Node group
# -----------------------------------

resource "aws_eks_node_group" "app" {
  cluster_name    = aws_eks_cluster.cluster.name
  node_group_name = "${var.project_name}-ng-app"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = [aws_subnet.public[1].id]
  scaling_config {
    desired_size = var.desired_capacity
    max_size     = 2
    min_size     = 1
  }

  instance_types = [var.node_instance_type]
  ami_type       = var.node_ami_type

  labels = {
    role = "app-ng"
  }

  tags = {
    Name = "${var.project_name}-ng-app"
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_AmazonEKSWorkerNodePolicy
  ]
}

resource "aws_eks_addon" "ebs_csi" {  
  cluster_name = aws_eks_cluster.cluster.name
  addon_name   = "aws-ebs-csi-driver"
  addon_version = "v1.53.0-eksbuild.1"
  service_account_role_arn = aws_iam_role.ebs_csi_role.arn
  depends_on = [
    aws_eks_node_group.jenkins,
    aws_eks_node_group.app
  ]
}