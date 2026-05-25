variable "project_name" {
  description = "Project slug"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "domain" {
  description = "Root domain"
  type        = string
}

variable "zone_id" {
  description = "Route53 hosted zone id in org account"
  type        = string
}

variable "org_route53_role_arn" {
  description = "Org route53 role arn"
  type        = string
}
