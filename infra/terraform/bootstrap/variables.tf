variable "project_name" {
  description = "Project slug used for naming"
  type        = string
}

variable "account_name" {
  description = "Account label (org, dev, prod)"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-2"
}

variable "github_owner" {
  description = "GitHub owner (user or org)"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
}

variable "deploy_role_name" {
  description = "Deploy role name override"
  type        = string
  default     = ""
}

variable "org_route53_role_arn" {
  description = "Org Route53 role ARN that env deploy role can assume"
  type        = string
  default     = ""
}
