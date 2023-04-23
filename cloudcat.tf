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

## add google mail MX records
resource "aws_route53_record" "cloudcat_mx" {
  zone_id = aws_route53_zone.cloudcat.zone_id
  name    = "cloudcat.digital"
  type    = "MX"
  ttl     = "86400"
  records = [
    "1 aspmx.l.google.com",
    "5 alt1.aspmx.l.google.com",
    "5 alt2.aspmx.l.google.com",
    "10 alt3.aspmx.l.google.com",
    "10 alt4.aspmx.l.google.com",
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

## add SPF for google mail
resource "aws_route53_record" "cloudcat_spf" {
  zone_id = aws_route53_zone.cloudcat.zone_id
  name    = "cloudcat.digital"
  type    = "TXT"
  ttl     = "86400"
  records = [
    "v=spf1 include:_spf.google.com ~all",
  ]
}

## add DKIM for google mail
resource "aws_route53_record" "cloudcat_dkim" {
  zone_id = aws_route53_zone.cloudcat.zone_id
  name    = "cloudcat._domainkey"
  type    = "TXT"
  ttl     = "86400"
  records = [
    "v=DKIM1; k=rsa; p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAhRRs49DQsnMDKFrBPPjAFu2NRjF5D/t5UgDI2Z8ge590VcVLPqTIy790KZef2TfpBkuRwx3wsm1SXXr3a0XKLs7lZSwuyYa/tWRl4zOPKcoHRX38nov2k+xEWpHtXiw5FqrFgihM0z2qX0fu1OigqMSHB3r3KVlhPYe0gKcamu6274yr+golnS22\"\"PrFMqCN3ux0dTC1Vr7xwEhmVXmQSue1yQnjsnJRvfNal+iZSAnWQkJVmmVakGPG/UHevVpLw0OyT+O4VSDMhz9hm/sqkQ4sQfomdihFQpnDa9BB1f47acW+Niqlsl1L2K7Bbejg3sNQYbrEpetU6wnm8a7peowIDAQAB"  ]
}

## add DMARC for google mail
resource "aws_route53_record" "cloudcat_dmarc" {
  zone_id = aws_route53_zone.cloudcat.zone_id
  name    = "_dmarc.cloudcat"
  type    = "TXT"
  ttl     = "86400"
  records = [
    "v=DMARC1; p=none; rua=mailto:matt@cloudcat.digital.com"
    ]
}