locals {
  apex_domain         = var.domain
  app_subdomain       = var.environment == "prod" ? "app" : "app-dev"
  app_domain_name     = "${local.app_subdomain}.${var.domain}"
  api_subdomain       = var.environment == "prod" ? "api" : "api-dev"
  api_domain_name     = "${local.api_subdomain}.${var.domain}"
  app_api_subdomain   = var.environment == "prod" ? "app-api" : "app-api-dev"
  app_api_domain_name = "${local.app_api_subdomain}.${var.domain}"
  app_ws_subdomain    = var.environment == "prod" ? "app-ws" : "app-ws-dev"
  app_ws_domain_name  = "${local.app_ws_subdomain}.${var.domain}"
  zone_id             = var.zone_id
  cloudfront_alias    = "Z2FDTNDATAQYW2"
  is_prod             = var.environment == "prod"
  cloudfront_certificate_domains = compact([
    local.app_domain_name,
    local.is_prod ? local.apex_domain : ""
  ])
  apigw_certificate_domains = compact([
    local.app_api_domain_name,
    local.app_ws_domain_name,
    local.api_domain_name
  ])
}

resource "aws_acm_certificate" "cloudfront" {
  provider = aws.us-east-1

  domain_name               = local.cloudfront_certificate_domains[0]
  subject_alternative_names = slice(local.cloudfront_certificate_domains, 1, length(local.cloudfront_certificate_domains))
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cloudfront_cert_validation" {
  provider = aws.org

  for_each = {
    for dvo in aws_acm_certificate.cloudfront.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  }

  allow_overwrite = true
  zone_id         = local.zone_id
  name            = each.value.name
  type            = each.value.type
  ttl             = 60
  records         = [each.value.record]
}

resource "aws_acm_certificate_validation" "cloudfront" {
  provider = aws.us-east-1

  certificate_arn         = aws_acm_certificate.cloudfront.arn
  validation_record_fqdns = [for record in aws_route53_record.cloudfront_cert_validation : record.fqdn]
}

resource "aws_acm_certificate" "apigw" {
  provider = aws

  domain_name               = local.apigw_certificate_domains[0]
  subject_alternative_names = slice(local.apigw_certificate_domains, 1, length(local.apigw_certificate_domains))
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "apigw_cert_validation" {
  provider = aws.org

  for_each = {
    for dvo in aws_acm_certificate.apigw.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  }

  allow_overwrite = true
  zone_id         = local.zone_id
  name            = each.value.name
  type            = each.value.type
  ttl             = 60
  records         = [each.value.record]
}

resource "aws_acm_certificate_validation" "apigw" {
  provider = aws

  certificate_arn         = aws_acm_certificate.apigw.arn
  validation_record_fqdns = [for record in aws_route53_record.apigw_cert_validation : record.fqdn]
}

resource "aws_s3_bucket" "apex" {
  count = local.is_prod ? 1 : 0

  bucket = local.apex_domain
}

resource "aws_s3_bucket_versioning" "apex" {
  count = local.is_prod ? 1 : 0

  bucket = aws_s3_bucket.apex[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "apex" {
  count = local.is_prod ? 1 : 0

  bucket = aws_s3_bucket.apex[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "apex" {
  count = local.is_prod ? 1 : 0

  bucket = aws_s3_bucket.apex[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket" "app" {
  bucket = local.app_domain_name
}

resource "aws_s3_bucket_versioning" "app" {
  bucket = aws_s3_bucket.app.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "app" {
  bucket = aws_s3_bucket.app.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "app" {
  bucket = aws_s3_bucket.app.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_cloudfront_origin_access_control" "apex" {
  provider = aws.us-east-1

  count = local.is_prod ? 1 : 0

  name                              = "${var.project_name}-${var.environment}-apex-oac"
  description                       = "OAC for ${local.apex_domain}"
  origin_access_control_origin_type = "s3"
  signing_protocol                  = "sigv4"
  signing_behavior                  = "always"
}

resource "aws_cloudfront_origin_access_control" "app" {
  provider = aws.us-east-1

  name                              = "${var.project_name}-${var.environment}-app-oac"
  description                       = "OAC for ${local.app_domain_name}"
  origin_access_control_origin_type = "s3"
  signing_protocol                  = "sigv4"
  signing_behavior                  = "always"
}

resource "aws_cloudfront_distribution" "apex" {
  provider = aws.us-east-1

  count = local.is_prod ? 1 : 0

  enabled             = true
  aliases             = [local.apex_domain]
  default_root_object = "index.html"

  origin {
    domain_name              = aws_s3_bucket.apex[0].bucket_regional_domain_name
    origin_id                = "apex-origin"
    origin_access_control_id = aws_cloudfront_origin_access_control.apex[0].id
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "apex-origin"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate.cloudfront.arn
    ssl_support_method  = "sni-only"
  }

  depends_on = [
    aws_acm_certificate_validation.cloudfront
  ]
}

resource "aws_cloudfront_distribution" "app" {
  provider = aws.us-east-1

  enabled             = true
  aliases             = [local.app_domain_name]
  default_root_object = "index.html"

  origin {
    domain_name              = aws_s3_bucket.app.bucket_regional_domain_name
    origin_id                = "app-origin"
    origin_access_control_id = aws_cloudfront_origin_access_control.app.id
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "app-origin"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
  }

  custom_error_response {
    error_code            = 403
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 0
  }

  custom_error_response {
    error_code            = 404
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 0
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate.cloudfront.arn
    ssl_support_method  = "sni-only"
  }

  depends_on = [
    aws_acm_certificate_validation.cloudfront
  ]
}

data "aws_iam_policy_document" "apex_bucket_policy" {
  count = local.is_prod ? 1 : 0

  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject"
    ]

    resources = [
      "${aws_s3_bucket.apex[0].arn}/*"
    ]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.apex[0].arn]
    }
  }
}

resource "aws_s3_bucket_policy" "apex" {
  count = local.is_prod ? 1 : 0

  bucket = aws_s3_bucket.apex[0].id
  policy = data.aws_iam_policy_document.apex_bucket_policy[0].json
}

data "aws_iam_policy_document" "app_bucket_policy" {
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject"
    ]

    resources = [
      "${aws_s3_bucket.app.arn}/*"
    ]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.app.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "app" {
  bucket = aws_s3_bucket.app.id
  policy = data.aws_iam_policy_document.app_bucket_policy.json
}

resource "aws_route53_record" "apex_alias" {
  provider = aws.org

  // count = local.is_prod ? 1 : 0
  count = 0 // temporary until ready to go live with new marketing site

  zone_id = local.zone_id
  name    = local.apex_domain
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.apex[0].domain_name
    zone_id                = local.cloudfront_alias
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "app_alias" {
  provider = aws.org

  zone_id = local.zone_id
  name    = local.app_domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.app.domain_name
    zone_id                = local.cloudfront_alias
    evaluate_target_health = false
  }
}

resource "aws_cognito_user_pool" "main" {
  name = "${var.project_name}-${var.environment}-user-pool"

  auto_verified_attributes = ["email"]
  username_attributes      = ["email"]

  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_uppercase = true
    require_numbers   = true
    require_symbols   = false
  }
}

resource "aws_cognito_user_pool_client" "app" {
  name         = "${var.project_name}-${var.environment}-app-client"
  user_pool_id = aws_cognito_user_pool.main.id

  explicit_auth_flows = [
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_PASSWORD_AUTH"
  ]

  generate_secret = false
}

resource "aws_cognito_user_group" "admin" {
  user_pool_id = aws_cognito_user_pool.main.id
  name         = "admin"
  description  = "Admin role"
}

resource "aws_cognito_user_group" "user" {
  user_pool_id = aws_cognito_user_pool.main.id
  name         = "user"
  description  = "Default user role"
}

resource "aws_ssm_parameter" "cognito_pool_id" {
  name  = "/${var.project_name}/${var.environment}/cognito/user-pool-id"
  type  = "String"
  value = aws_cognito_user_pool.main.id
}

resource "aws_ssm_parameter" "cognito_client_id" {
  name  = "/${var.project_name}/${var.environment}/cognito/app-client-id"
  type  = "String"
  value = aws_cognito_user_pool_client.app.id
}

resource "aws_ssm_parameter" "apigw_cert_arn" {
  name  = "/${var.project_name}/${var.environment}/acm/apigw-certificate-arn"
  type  = "String"
  value = aws_acm_certificate.apigw.arn
}

resource "aws_ssm_parameter" "cloudfront_cert_arn" {
  name  = "/${var.project_name}/${var.environment}/acm/cloudfront-certificate-arn"
  type  = "String"
  value = aws_acm_certificate.cloudfront.arn
}

resource "aws_ssm_parameter" "frontend_apex_bucket" {
  count = local.is_prod ? 1 : 0

  name  = "/${var.project_name}/${var.environment}/frontend/apex-bucket"
  type  = "String"
  value = aws_s3_bucket.apex[0].bucket
}

resource "aws_ssm_parameter" "frontend_app_bucket" {
  name  = "/${var.project_name}/${var.environment}/frontend/app-bucket"
  type  = "String"
  value = aws_s3_bucket.app.bucket
}

resource "aws_ssm_parameter" "frontend_apex_distribution_id" {
  count = local.is_prod ? 1 : 0

  name  = "/${var.project_name}/${var.environment}/frontend/apex-distribution-id"
  type  = "String"
  value = aws_cloudfront_distribution.apex[0].id
}

resource "aws_ssm_parameter" "frontend_app_distribution_id" {
  name  = "/${var.project_name}/${var.environment}/frontend/app-distribution-id"
  type  = "String"
  value = aws_cloudfront_distribution.app.id
}
