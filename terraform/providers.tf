terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Read cluster info
data "aws_eks_cluster" "cluster" {
  name = var.project_name
  depends_on = [aws_eks_cluster.cluster]
}

data "aws_eks_cluster_auth" "cluster" {
  name = var.project_name
  depends_on = [aws_eks_cluster.cluster]
}

# Kubernetes provider configured to talk to the target cluster (uses the aws eks auth token)
provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}



