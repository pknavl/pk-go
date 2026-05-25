provider "aws" {
  region = var.region
}

provider "aws" {
  alias  = "us-east-1"
  region = "us-east-1"
}

provider "aws" {
  alias = "org"

  assume_role {
    role_arn = var.org_route53_role_arn
  }

  region = var.region
}
