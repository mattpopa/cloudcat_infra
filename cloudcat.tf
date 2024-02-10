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

## ################################################################################################
## DNS records
## ################################################################################################

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

## validations and SPF checks
resource "aws_route53_record" "cloudcat_spf" {
  zone_id = aws_route53_zone.cloudcat.zone_id
  name    = local.base_domain
  type    = "TXT"
  ttl     = "86400"
  records = [
    "v=spf1 include:_spf.google.com include:zoho.eu ~all",
    "zoho-verification=zb27550133.zmverify.zoho.eu",
    "google-site-verification=yeC1LX83Ee3XOViZOBbaSi2VgDPQC1nlY4MVZVXTNqI"
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

# Apex domain - A and AAAA records pointing to GitHub Pages
resource "aws_route53_record" "cloudcat_apex" {
  allow_overwrite = true
  zone_id = aws_route53_zone.cloudcat.zone_id
  name    = local.base_domain
  type    = "A"
  ttl     = "86400"
  records = local.github_pages_ipv4
}

resource "aws_route53_record" "cloudcat_apex_v6" {
  allow_overwrite = true
  zone_id = aws_route53_zone.cloudcat.zone_id
  name    = local.base_domain
  type    = "AAAA"
  ttl     = "86400"
  records = local.github_pages_ipv6
}

# Subdomain www - CNAME record pointing to GitHub Pages
resource "aws_route53_record" "www_subdomain" {
  allow_overwrite = true
  zone_id = aws_route53_zone.cloudcat.zone_id
  name    = "www.${local.base_domain}"
  type    = "CNAME"
  ttl     = "86400"
  records = [
    local.gh_pages_domain
  ]
}

# Subdomain blog - CNAME record pointing to GitHub Pages
resource "aws_route53_record" "blog_subdomain" {
  allow_overwrite = true
  zone_id = aws_route53_zone.cloudcat.zone_id
  name    = "blog.${local.base_domain}"
  type    = "CNAME"
  ttl     = "86400"
  records = [
    local.gh_pages_domain
  ]
}
