variable "project_name" {
  description = "Project slug"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-2"
}

variable "domain" {
  description = "Root domain"
  type        = string
}

variable "zone_id" {
  description = "Route53 hosted zone ID"
  type        = string
}

variable "trusted_role_arns" {
  description = "List of IAM role ARNs allowed to assume Route53 management role"
  type        = list(string)
}

variable "aws_signin_redirect_enabled" {
  description = "Enable aws.<domain> redirect to IAM Identity Center start URL"
  type        = bool
  default     = false
}

variable "aws_signin_start_url" {
  description = "IAM Identity Center start URL for redirect target"
  type        = string
  default     = ""
}

variable "aws_signin_redirect_subdomain" {
  description = "Subdomain used for sign-in redirect (for example aws.example.com)"
  type        = string
  default     = ""
}
