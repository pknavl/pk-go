output "route53_zone_id" {
  description = "Route53 hosted zone ID"
  value       = data.aws_route53_zone.main.zone_id
}

output "org_route53_role_arn" {
  description = "Role ARN to assume for cross-account Route53 updates"
  value       = aws_iam_role.route53_manager.arn
}

output "aws_signin_redirect_domain" {
  description = "Route53 record for AWS sign-in redirect"
  value       = var.aws_signin_redirect_enabled ? local.aws_signin_redirect_host : ""
}
