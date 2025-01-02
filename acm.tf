module "acm" {
  source  = "terraform-aws-modules/acm/aws"
  version = "5.1.0"

  domain_name = local.base_domain
  zone_id     =  data.aws_route53_zone.base.zone_id

  subject_alternative_names = [
    "*.${local.base_domain}"
  ]

  validation_method = "DNS"

  tags = {
    Name        = local.base_domain
  }
}
