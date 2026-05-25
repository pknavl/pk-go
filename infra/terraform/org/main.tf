data "aws_route53_zone" "main" {
  zone_id = var.zone_id
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"
    actions = [
      "sts:AssumeRole"
    ]

    principals {
      type = "AWS"
      identifiers = [
        for arn in var.trusted_role_arns :
        format("arn:aws:iam::%s:root", split(":", arn)[4])
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalAccount"
      values = distinct([
        for arn in var.trusted_role_arns : split(":", arn)[4]
      ])
    }
  }
}

resource "aws_iam_role" "route53_manager" {
  name               = "${var.project_name}-route53-manager"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "route53_manage" {
  statement {
    effect = "Allow"
    actions = [
      "route53:GetHostedZone",
      "route53:GetChange",
      "route53:ListHostedZones",
      "route53:ListResourceRecordSets"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "route53:ChangeResourceRecordSets"
    ]
    resources = [
      data.aws_route53_zone.main.arn
    ]
  }
}

resource "aws_iam_role_policy" "route53_manage" {
  name   = "${var.project_name}-route53-manage"
  role   = aws_iam_role.route53_manager.name
  policy = data.aws_iam_policy_document.route53_manage.json
}

locals {
  aws_signin_redirect_host = trimspace(var.aws_signin_redirect_subdomain) != "" ? trimspace(var.aws_signin_redirect_subdomain) : "aws.${var.domain}"
}

resource "aws_acm_certificate" "aws_signin_redirect" {
  provider = aws.us-east-1
  count    = var.aws_signin_redirect_enabled ? 1 : 0

  domain_name       = local.aws_signin_redirect_host
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "aws_signin_redirect_cert_validation" {
  for_each = var.aws_signin_redirect_enabled ? {
    for dvo in aws_acm_certificate.aws_signin_redirect[0].domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  } : {}

  allow_overwrite = true
  zone_id         = data.aws_route53_zone.main.zone_id
  name            = each.value.name
  type            = each.value.type
  ttl             = 60
  records         = [each.value.record]
}

resource "aws_acm_certificate_validation" "aws_signin_redirect" {
  provider = aws.us-east-1
  count    = var.aws_signin_redirect_enabled ? 1 : 0

  certificate_arn         = aws_acm_certificate.aws_signin_redirect[0].arn
  validation_record_fqdns = [for record in aws_route53_record.aws_signin_redirect_cert_validation : record.fqdn]
}

resource "aws_s3_bucket" "aws_signin_redirect" {
  count = var.aws_signin_redirect_enabled ? 1 : 0

  bucket = local.aws_signin_redirect_host
}

resource "aws_s3_bucket_website_configuration" "aws_signin_redirect" {
  count = var.aws_signin_redirect_enabled ? 1 : 0

  bucket = aws_s3_bucket.aws_signin_redirect[0].id

  index_document {
    suffix = "index.html"
  }
}

resource "aws_s3_object" "aws_signin_redirect_index" {
  count = var.aws_signin_redirect_enabled ? 1 : 0

  bucket       = aws_s3_bucket.aws_signin_redirect[0].id
  key          = "index.html"
  content_type = "text/html"
  content      = "<html><body>Redirecting...</body></html>"
}

resource "aws_s3_bucket_public_access_block" "aws_signin_redirect" {
  count = var.aws_signin_redirect_enabled ? 1 : 0

  bucket = aws_s3_bucket.aws_signin_redirect[0].id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

data "aws_iam_policy_document" "aws_signin_redirect" {
  count = var.aws_signin_redirect_enabled ? 1 : 0

  statement {
    sid     = "AllowPublicRead"
    effect  = "Allow"
    actions = ["s3:GetObject"]
    resources = [
      "${aws_s3_bucket.aws_signin_redirect[0].arn}/*"
    ]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
  }
}

resource "aws_s3_bucket_policy" "aws_signin_redirect" {
  count = var.aws_signin_redirect_enabled ? 1 : 0

  bucket = aws_s3_bucket.aws_signin_redirect[0].id
  policy = data.aws_iam_policy_document.aws_signin_redirect[0].json
}

resource "aws_cloudfront_function" "aws_signin_redirect" {
  count = var.aws_signin_redirect_enabled ? 1 : 0

  name    = "${var.project_name}-aws-signin-redirect"
  runtime = "cloudfront-js-2.0"
  publish = true
  code    = <<-EOT
function handler(event) {
  return {
    statusCode: 302,
    statusDescription: "Found",
    headers: {
      location: { value: "${var.aws_signin_start_url}" },
      "cache-control": { value: "no-store" }
    }
  };
}
EOT
}

resource "aws_cloudfront_distribution" "aws_signin_redirect" {
  provider = aws.us-east-1
  count    = var.aws_signin_redirect_enabled ? 1 : 0

  enabled = true
  aliases = [local.aws_signin_redirect_host]

  origin {
    domain_name = aws_s3_bucket_website_configuration.aws_signin_redirect[0].website_endpoint
    origin_id   = "aws-signin-redirect-origin"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "aws-signin-redirect-origin"

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.aws_signin_redirect[0].arn
    }

    forwarded_values {
      query_string = true
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 0
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.aws_signin_redirect[0].arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  depends_on = [
    aws_acm_certificate_validation.aws_signin_redirect
  ]
}

resource "aws_route53_record" "aws_signin_redirect" {
  count = var.aws_signin_redirect_enabled ? 1 : 0

  zone_id = data.aws_route53_zone.main.zone_id
  name    = local.aws_signin_redirect_host
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.aws_signin_redirect[0].domain_name
    zone_id                = aws_cloudfront_distribution.aws_signin_redirect[0].hosted_zone_id
    evaluate_target_health = false
  }
}
