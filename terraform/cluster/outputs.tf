output "cluster_name" {
  description = "Name of the cluster."
  value       = aws_eks_cluster.this.name
}

output "cluster_endpoint" {
  description = "Kubernetes API endpoint."
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_certificate_authority" {
  description = "Base64-encoded cluster CA certificate."
  value       = aws_eks_cluster.this.certificate_authority[0].data
}

output "oidc_provider_arn" {
  description = "ARN of the cluster's IAM OIDC provider."
  value       = aws_iam_openid_connect_provider.this.arn
}

output "irsa_role_arns" {
  description = "IAM role ARN for each service account that uses IRSA."
  value       = { for name, role in aws_iam_role.irsa : name => role.arn }
}
