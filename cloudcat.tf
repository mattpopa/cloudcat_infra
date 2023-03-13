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

