variable "project_name" {
  description = "Project slug"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-2"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "domain" {
  description = "Root domain"
  type        = string
}

variable "zone_id" {
  description = "Hosted zone id"
  type        = string
}

variable "org_route53_role_arn" {
  description = "Org route53 role arn"
  type        = string
}
