## ################################################################################################
## AWS billing alert if monthly spending is over $20
## ################################################################################################
resource "aws_sns_topic" "billing_alert" {
  name = "billing-alert"
}

resource "aws_sns_topic_subscription" "billing_alert" {
  topic_arn = aws_sns_topic.billing_alert.arn
  protocol  = "email"
  endpoint  = var.cloudcat_contact
}

resource "aws_cloudwatch_metric_alarm" "billing_alert" {
  alarm_name          = "billing-alert"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "EstimatedCharges"
  namespace           = "AWS/Billing"
  period              = "86400"
  statistic           = "Maximum"
  threshold           = "20"
  alarm_description   = "This metric monitors AWS Billing for cloudcat.digital"
  alarm_actions       = [aws_sns_topic.billing_alert.arn]
}

## ################################################################################################
## DNS zone
## ################################################################################################

resource "aws_route53_zone" "cloudcat" {
  name = local.base_domain
}

resource "aws_route53_record" "cloudcat_mx" {
  zone_id = aws_route53_zone.cloudcat.zone_id
  name    = local.base_domain
  type    = "MX"
  ttl     = "86400"
  records = [
    "10 mx.zoho.eu",
    "20 mx2.zoho.eu",
    "50 mx3.zoho.eu"
  ]
}

resource "aws_route53_record" "cloudcat_mattpopa_redirect" {
  zone_id = aws_route53_zone.cloudcat.zone_id
  name    = aws_route53_zone.cloudcat.name
  type    = "A"

  alias {
    name    = aws_s3_bucket_website_configuration.cloudcat_digital_redirect_config.website_domain
    zone_id = local.s3_eu_west_2_id

    evaluate_target_health = false
  }
}

resource "aws_route53_record" "www_cloudcat_mattpopa_redirect" {
  zone_id = aws_route53_zone.cloudcat.zone_id
  name    = "www.${aws_route53_zone.cloudcat.name}"
  type    = "A"

  alias {
    name    = aws_s3_bucket_website_configuration.cloudcat_digital_redirect_config.website_domain
    zone_id = local.s3_eu_west_2_id

    evaluate_target_health = false
  }
}

resource "aws_route53_record" "blog_cloudcat_mattpopa_redirect" {
  zone_id = aws_route53_zone.cloudcat.zone_id
  name    = "blog.${aws_route53_zone.cloudcat.name}"
  type    = "A"

  alias {
    name    = aws_s3_bucket_website_configuration.cloudcat_digital_redirect_config.website_domain
    zone_id = local.s3_eu_west_2_id

    evaluate_target_health = false
  }
}

## validations and SPF checks
resource "aws_route53_record" "cloudcat_spf" {
  zone_id = aws_route53_zone.cloudcat.zone_id
  name    = local.base_domain
  type    = "TXT"
  ttl     = "86400"
  records = [
    "v=spf1 include:_spf.google.com include:zoho.eu ~all",
    "zoho-verification=zb27550133.zmverify.zoho.eu"
  ]
}

resource "aws_route53_record" "cloudcat_dkim" {
  zone_id = aws_route53_zone.cloudcat.zone_id
  name    = "zmail._domainkey"
  type    = "TXT"
  ttl     = "86400"
  records = [
    "v=DKIM1; k=rsa; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCz+gemYlm/HfVY7sU1HhLkAFQsf/tviwKFvC/A0a8en/zPHE+smU3/G2RX0aUwm8x5IZjROoI5cZgAA2yhI1ZtLFRoEhmE+kVHINpnPepJVlVkuw\"\"JkI+xXRjvVKerzw/XLjzIhSwmvKFVuYCKWOpXdxiUoinC2KL073KUP+GbG+QIDAQAB"
  ]
}

resource "aws_route53_record" "cloudcat_dmarc" {
  zone_id = aws_route53_zone.cloudcat.zone_id
  name    = "_dmarc.cloudcat"
  type    = "TXT"
  ttl     = "86400"
  records = [
    "v=DMARC1; p=none; rua=mailto:${var.cloudcat_contact}"
    ]
}

# add CNAME for github pages domain validation
resource "aws_route53_record" "cloudcat_github_pages" {
  zone_id = aws_route53_zone.cloudcat.zone_id
  name    = "_github-pages-challenge-mattpopa"
  type    = "TXT"
  ttl     = "86400"
  records = [
    "8acc83cbc636acceadcd63a9803691"
  ]
}

## ################################################################################################
## S3 DNS redirect for HTTP-Level 301
## ################################################################################################

resource "aws_s3_bucket" "cloudcat_digital_redirect" {
  bucket = local.base_domain
}

resource "aws_s3_bucket_public_access_block" "cloudcat_digital_redirect" {
  bucket = aws_s3_bucket.cloudcat_digital_redirect.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_ownership_controls" "cloudcat_digital_redirect" {
  bucket = aws_s3_bucket.cloudcat_digital_redirect.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}
resource "aws_s3_bucket_acl" "cloudcat_digital_redirect_acl" {
  bucket = aws_s3_bucket.cloudcat_digital_redirect.id
  acl    = "public-read"
  depends_on = [
    aws_s3_bucket_public_access_block.cloudcat_digital_redirect,
    aws_s3_bucket_ownership_controls.cloudcat_digital_redirect
  ]
}

resource "aws_s3_bucket_website_configuration" "cloudcat_digital_redirect_config" {
  bucket = aws_s3_bucket.cloudcat_digital_redirect.id

  redirect_all_requests_to {
    host_name = local.gh_pages_domain
    protocol  = "https"
  }
}

## ################################################################################################
## ACM certificate
## ################################################################################################

resource "aws_acm_certificate" "cert_cloudfront_distribution" {
  validation_method = "DNS"
  provider          = aws.use1
  domain_name       = local.base_domain

  subject_alternative_names = [
    "*.${local.base_domain}"
  ]
  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${local.base_domain}-cert"
  }
}

## ################################################################################################
## ACM certificate validation
## ################################################################################################

resource "aws_route53_record" "validation_cert_cloudfront_distribution" {
  allow_overwrite = true
  for_each = {
    for dvo in aws_acm_certificate.cert_cloudfront_distribution.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  zone_id = data.aws_route53_zone.base.zone_id
  name    = each.value.name
  type    = each.value.type
  records = [each.value.record]
  ttl     = 60
}

## ################################################################################################
## CloudFront distribution
## ################################################################################################

resource "aws_cloudfront_distribution" "cloudcat_digital" {

  origin {
    domain_name = local.base_domain
    origin_id   = local.base_domain

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  enabled         = true
  is_ipv6_enabled = true
  aliases = [
    "cloudcat.digital",
    "www.cloudcat.digital",
    "blog.cloudcat.digital"
  ]

  default_cache_behavior {
    target_origin_id       = local.base_domain
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = true
      headers      = ["*"]

      cookies {
        forward = "all"
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate.cert_cloudfront_distribution.arn
    ssl_support_method  = "sni-only"
  }
}