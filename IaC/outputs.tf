output "cluster_id" {
  description = "The name/id of the EKS cluster"
  value       = aws_eks_cluster.main.id
}

output "cluster_arn" {
  description = "The Amazon Resource Name (ARN) of the cluster"
  value       = aws_eks_cluster.main.arn
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = aws_security_group.cluster.id
}

output "node_security_group_id" {
  description = "Security group ID attached to the EKS nodes"
  value       = aws_security_group.node.id
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = aws_eks_cluster.main.certificate_authority[0].data
  sensitive   = true
}

output "cluster_iam_role_arn" {
  description = "IAM role ARN of the EKS cluster"
  value       = aws_iam_role.cluster.arn
}

output "node_group_iam_role_arn" {
  description = "IAM role ARN of the EKS node group"
  value       = aws_iam_role.node_group.arn
}

output "node_group_id" {
  description = "EKS node group ID"
  value       = aws_eks_node_group.main.id
}

output "kms_key_id" {
  description = "KMS key ID for EKS secrets encryption"
  value       = aws_kms_key.eks.key_id
}

output "kms_key_arn" {
  description = "KMS key ARN for EKS secrets encryption"
  value       = aws_kms_key.eks.arn
}

output "ebs_kms_key_id" {
  description = "KMS key ID for EBS encryption"
  value       = aws_kms_key.ebs.key_id
}

output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group for EKS logs"
  value       = aws_cloudwatch_log_group.eks.name
}

output "oidc_provider_arn" {
  description = "ARN of the OIDC Provider for EKS"
  value       = aws_iam_openid_connect_provider.eks.arn
}
