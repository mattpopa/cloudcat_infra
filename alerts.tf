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
