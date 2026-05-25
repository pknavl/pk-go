module "main" {
  source = "../main"

  project_name         = var.project_name
  region               = var.region
  environment          = var.environment
  domain               = var.domain
  zone_id              = var.zone_id
  org_route53_role_arn = var.org_route53_role_arn
}
