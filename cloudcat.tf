## ################################################################################################
## create AWS billing alert if monthly spending is over $20
## ################################################################################################
## create the sns topic
resource "aws_sns_topic" "billing_alert" {
  name = "billing-alert"
}

## create the sns topic subscription
resource "aws_sns_topic_subscription" "billing_alert" {
  topic_arn = aws_sns_topic.billing_alert.arn
  protocol  = "email"
  endpoint  = var.cloudcat_contact
}

## create the cloudwatch metric alarm
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
## create the DNS zone for cloudcat.digital
## ################################################################################################
resource "aws_route53_zone" "cloudcat" {
  name = "cloudcat.digital"
}

## add zoho mail MX records
resource "aws_route53_record" "cloudcat_mx" {
  zone_id = aws_route53_zone.cloudcat.zone_id
  name    = "cloudcat.digital"
  type    = "MX"
  ttl     = "86400"
  records = [
    "10 mx.zoho.eu",
    "20 mx2.zoho.eu",
    "50 mx3.zoho.eu"
  ]
}

## add CNAME for mattpopa.gihub.io
resource "aws_route53_record" "cloudcat_mattpopa" {
  zone_id = aws_route53_zone.cloudcat.zone_id
  name    = "blog.cloudcat.digital"
  type    = "CNAME"
  ttl     = "86400"
  records = [
    "mattpopa.github.io.",
  ]
}

## validations and SPF checks
resource "aws_route53_record" "cloudcat_spf" {
  zone_id = aws_route53_zone.cloudcat.zone_id
  name    = "cloudcat.digital"
  type    = "TXT"
  ttl     = "86400"
  records = [
    "v=spf1 include:_spf.google.com include:zoho.eu ~all",
    "zoho-verification=zb27550133.zmverify.zoho.eu"
  ]
}

## add DKIM for google mail
resource "aws_route53_record" "cloudcat_dkim" {
  zone_id = aws_route53_zone.cloudcat.zone_id
  name    = "zmail._domainkey"
  type    = "TXT"
  ttl     = "86400"
  records = [
    "v=DKIM1; k=rsa; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCz+gemYlm/HfVY7sU1HhLkAFQsf/tviwKFvC/A0a8en/zPHE+smU3/G2RX0aUwm8x5IZjROoI5cZgAA2yhI1ZtLFRoEhmE+kVHINpnPepJVlVkuw\"\"JkI+xXRjvVKerzw/XLjzIhSwmvKFVuYCKWOpXdxiUoinC2KL073KUP+GbG+QIDAQAB"
  ]
}

## add DMARC for google mail
resource "aws_route53_record" "cloudcat_dmarc" {
  zone_id = aws_route53_zone.cloudcat.zone_id
  name    = "_dmarc.cloudcat"
  type    = "TXT"
  ttl     = "86400"
  records = [
    "v=DMARC1; p=none; rua=mailto:${var.cloudcat_contact}"
    ]
}