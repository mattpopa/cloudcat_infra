module "acm" {
  source  = "terraform-aws-modules/acm/aws"
  version = "5.1.0"

  domain_name = local.base_domain
  zone_id     = data.aws_route53_zone.base.zone_id

  subject_alternative_names = [
    "*.${local.base_domain}"
  ]

  validation_method = "DNS"

  tags = {
    Name = local.base_domain
  }
}

module "host1" {
  source  = "terraform-aws-modules/acm/aws"
  version = "5.1.0"

  domain_name = local.host1
  zone_id     = aws_route53_zone.host1.zone_id

  subject_alternative_names = [
    "*.${local.host1}"
  ]

  validation_method = "DNS"

  tags = {
    Name = local.host1
  }
}

module "host2" {
  source  = "terraform-aws-modules/acm/aws"
  version = "5.1.0"

  domain_name = local.host2
  zone_id     = aws_route53_zone.host2.zone_id

  subject_alternative_names = [
    "*.${local.host2}"
  ]

  validation_method = "DNS"

  tags = {
    Name = local.host2
  }
}
