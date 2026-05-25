output "apex_bucket" {
  description = "Apex marketing bucket"
  value       = local.is_prod ? aws_s3_bucket.apex[0].bucket : ""
}

output "app_bucket" {
  description = "App frontend bucket"
  value       = aws_s3_bucket.app.bucket
}

output "apex_distribution_id" {
  description = "Apex CloudFront distribution id"
  value       = local.is_prod ? aws_cloudfront_distribution.apex[0].id : ""
}

output "app_distribution_id" {
  description = "App CloudFront distribution id"
  value       = aws_cloudfront_distribution.app.id
}

output "cognito_user_pool_id" {
  description = "Cognito user pool id"
  value       = aws_cognito_user_pool.main.id
}

output "cognito_app_client_id" {
  description = "Cognito app client id"
  value       = aws_cognito_user_pool_client.app.id
}

output "apigw_certificate_arn" {
  description = "Regional ACM certificate for API Gateway custom domains"
  value       = aws_acm_certificate.apigw.arn
}
