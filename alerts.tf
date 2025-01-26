# SNS Topic in us-east-1
resource "aws_sns_topic" "billing_alert_us" {
  provider = aws.use1
  name     = "billing-alert-us"
}

resource "aws_sns_topic_subscription" "billing_alert_us_subscription" {
  provider  = aws.use1
  topic_arn = aws_sns_topic.billing_alert_us.arn
  protocol  = "email"
  endpoint  = var.cloudcat_contact
}

# Billing Alarm in us-east-1
resource "aws_cloudwatch_metric_alarm" "billing_alert" {
  provider            = aws.use1
  alarm_name          = "billing-alert"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "EstimatedCharges"
  namespace           = "AWS/Billing"
  period              = "21600"
  statistic           = "Maximum"
  threshold           = "40"
  alarm_description   = "This metric monitors AWS Billing for cloudcat.digital"
  alarm_actions       = [aws_sns_topic.billing_alert_us.arn]
}

## #############################################################################
## Health alerts
## #############################################################################

# SNS Topic in eu-central-1
resource "aws_sns_topic" "health_alert_eu" {
  name = "health-alert-eu"
}

resource "aws_sns_topic_subscription" "health_alert_eu_subscription" {
  topic_arn = aws_sns_topic.health_alert_eu.arn
  protocol  = "email"
  endpoint  = var.cloudcat_contact
}

# Health Alert for Host1
resource "aws_cloudwatch_metric_alarm" "host1_status_check_failed" {
  provider            = aws
  alarm_name          = "Host1-StatusCheckFailed"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Maximum"
  threshold           = 1
  alarm_description   = "Alarm if Host1 fails EC2 status checks"
  alarm_actions       = [aws_sns_topic.health_alert_eu.arn]
  dimensions = {
    InstanceId = aws_instance.host1.id
  }
}

# Health Alert for Host2
resource "aws_cloudwatch_metric_alarm" "host2_status_check_failed" {
  provider            = aws
  alarm_name          = "Host2-StatusCheckFailed"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Maximum"
  threshold           = 1
  alarm_description   = "Alarm if Host2 fails EC2 status checks"
  alarm_actions       = [aws_sns_topic.health_alert_eu.arn]
  dimensions = {
    InstanceId = aws_instance.host2.id
  }
}
