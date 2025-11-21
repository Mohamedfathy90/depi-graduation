output "cluster_name" {
  value = aws_eks_cluster.cluster.name
}

output "cluster_endpoint" {
  value = aws_eks_cluster.cluster.endpoint
}

output "nodegroup_jenkins" {
  value = aws_eks_node_group.jenkins.node_group_name
}

output "nodegroup_app" {
  value = aws_eks_node_group.app.node_group_name
}
