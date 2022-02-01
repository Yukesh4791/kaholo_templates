locals {
  # Use existing (via data source) or create new zone (will fail validation, if zone is not reachable)
  use_existing_route53_zone = true

#  domain_name = "example.com"
}

variable "domain_name" {
  type        = string
  description = "Domain name"
}
data "aws_route53_zone" "this" {
  count = local.use_existing_route53_zone ? 1 : 0

  name         = var.domain_name
  private_zone = false
}

resource "aws_route53_zone" "this" {
  count = !local.use_existing_route53_zone ? 1 : 0
  name  = var.domain_name
}

module "acm" {
  source = "terraform-aws-modules/acm/aws"

  domain_name = var.domain_name
  zone_id     = coalescelist(data.aws_route53_zone.this.*.zone_id, aws_route53_zone.this.*.zone_id)[0]

  subject_alternative_names = [
    "*.alerts.${var.domain_name}",
    "new.sub.${var.domain_name}",
    "*.${var.domain_name}",
    "alerts.${var.domain_name}",
  ]

  wait_for_validation = true

  tags = {
    Name = var.domain_name
  }
}