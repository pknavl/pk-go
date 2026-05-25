output "github_actions_oidc_provider_arn" {
  description = "GitHub OIDC provider ARN"
  value       = aws_iam_openid_connect_provider.github_actions.arn
}

output "github_deploy_role_arn" {
  description = "Deploy role ARN for GitHub Actions"
  value       = aws_iam_role.github_deploy.arn
}
