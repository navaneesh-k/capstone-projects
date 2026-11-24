
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-southeast-1"
}

resource "aws_cloudwatch_dashboard" "project21" {
  dashboard_name = "project21-monitoring-nk"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "text"
        x      = 0
        y      = 0
        width  = 24
        height = 2

        properties = {
          markdown = "# Project 21 - AWS CloudWatch Monitoring\nSimulated performance monitoring dashboard"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 2
        width  = 12
        height = 6

        properties = {
          title  = "Simulated CPU Utilization"
          region = "ap-southeast-1"
          metrics = [
            ["Project21-NK", "CPUUtilization"]
          ]
          stat   = "Average"
          period = 300
          view   = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 2
        width  = 12
        height = 6

        properties = {
          title  = "Simulated Network Traffic"
          region = "ap-southeast-1"
          metrics = [
            ["Project21-NK", "NetworkIn"],
            [".", "NetworkOut"]
          ]
          stat   = "Sum"
          period = 300
          view   = "timeSeries"
        }
      }
    ]
  })
}

output "dashboard_name" {
  value = aws_cloudwatch_dashboard.project21.dashboard_name
}
