
# SNS Topic for Alerts (if email provided)
resource "aws_sns_topic" "alerts" {
  count = var.notification_email != "" ? 1 : 0
  name  = "${var.project_name}-alerts"

  tags = local.common_tags
}

resource "aws_sns_topic_subscription" "email_alerts" {
  count     = var.notification_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.alerts[0].arn
  protocol  = "email"
  endpoint  = var.notification_email
}

resource "aws_cloudwatch_metric_alarm" "alb_target_response_time" {
  count = var.enable_monitoring ? 1 : 0

  alarm_name          = "${var.project_name}-alb-high-response-time"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = "300"
  statistic           = "Average"
  threshold           = "1"
  alarm_description   = "This metric monitors ALB response time"
  alarm_actions       = var.notification_email != "" ? [aws_sns_topic.alerts[0].arn] : []

  dimensions = {
    LoadBalancer = aws_lb.main.arn_suffix
  }

  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "alb_healthy_host_count" {
  count = var.enable_monitoring ? 1 : 0

  alarm_name          = "${var.project_name}-alb-low-healthy-hosts"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "HealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = "300"
  statistic           = "Average"
  threshold           = "1"
  alarm_description   = "This metric monitors healthy host count"
  alarm_actions       = var.notification_email != "" ? [aws_sns_topic.alerts[0].arn] : []

  dimensions = {
    TargetGroup  = aws_lb_target_group.backend.arn_suffix
    LoadBalancer = aws_lb.main.arn_suffix
  }

  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "ecs_cpu_high" {
  count = var.enable_monitoring ? 1 : 0

  alarm_name          = "${var.project_name}-ecs-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors ECS CPU utilization"
  alarm_actions       = var.notification_email != "" ? [aws_sns_topic.alerts[0].arn] : []

  dimensions = {
    ServiceName = aws_ecs_service.backend.name
    ClusterName = aws_ecs_cluster.main.name
  }

  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "ecs_memory_high" {
  count = var.enable_monitoring ? 1 : 0

  alarm_name          = "${var.project_name}-ecs-high-memory"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors ECS memory utilization"
  alarm_actions       = var.notification_email != "" ? [aws_sns_topic.alerts[0].arn] : []

  dimensions = {
    ServiceName = aws_ecs_service.backend.name
    ClusterName = aws_ecs_cluster.main.name
  }

  tags = local.common_tags
}

resource "aws_cloudwatch_dashboard" "main" {
  count          = var.enable_monitoring ? 1 : 0
  dashboard_name = "${var.project_name}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", aws_lb.main.arn_suffix],
            [".", "TargetResponseTime", ".", "."],
            [".", "HTTPCode_Target_2XX_Count", ".", "."],
            [".", "HTTPCode_Target_4XX_Count", ".", "."],
            [".", "HTTPCode_Target_5XX_Count", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "Application Load Balancer Metrics"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ServiceName", aws_ecs_service.backend.name, "ClusterName", aws_ecs_cluster.main.name],
            [".", "MemoryUtilization", ".", ".", ".", "."],
            [".", "RunningTaskCount", ".", ".", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "ECS Service Metrics"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 12
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/CloudFront", "Requests", "DistributionId", aws_cloudfront_distribution.frontend.id],
            [".", "BytesDownloaded", ".", "."],
            [".", "4xxErrorRate", ".", "."],
            [".", "5xxErrorRate", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = "us-east-1"
          title   = "CloudFront Metrics"
          period  = 300
        }
      }
    ]
  })
}