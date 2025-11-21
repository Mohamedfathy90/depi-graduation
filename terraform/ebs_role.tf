# --------------------------------
# Creating new IAM role for EBS 
# --------------------------------

# extract OIDC issuer and id
locals {
  oidc_issuer_full = data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer
  oidc_id          = replace(local.oidc_issuer_full, "https://", "")
  oidc_host        = local.oidc_id # "oidc.eks.<region>.amazonaws.com/id/<OIDC_ID>"
}

# Get TLS fingerprint (thumbprint) for the OIDC issuer
data "tls_certificate" "oidc" {
  url = local.oidc_issuer_full
}

resource "aws_iam_openid_connect_provider" "eks_oidc" {
  url             = local.oidc_issuer_full
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.oidc.certificates[0].sha1_fingerprint]
}

# Role name fallback
locals {
  final_role_name = "AmazonEKS_EBS_CSI_DriverRole-${var.project_name}"
}

# IAM role for EBS CSI driver with proper trust policy 
resource "aws_iam_role" "ebs_csi_role" {
  name = local.final_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Federated = aws_iam_openid_connect_provider.eks_oidc.arn }
        Action    = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${local.oidc_host}:sub" = "system:serviceaccount:kube-system:ebs-csi-controller-sa"
          }
        }
      }
    ]
  })
}

# Attach the AWS-managed policy for EBS CSI driver
resource "aws_iam_role_policy_attachment" "attach_ebs_policy" {
  role       = aws_iam_role.ebs_csi_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}
