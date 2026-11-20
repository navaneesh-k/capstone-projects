terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Find the latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Create EC2 instance
resource "aws_instance" "monitoring_ec2" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"
  monitoring    = true
  user_data     = file("${path.module}/user_data.sh")

  metadata_options {
    http_tokens = "required"
  }

  tags = {
    Name = "Project3-CloudWatch-EC2"
  }
}

# Create CloudWatch CPU alarm
resource "aws_cloudwatch_metric_alarm" "cpu_alarm" {
  alarm_name        = "project3-high-cpu-alarm"
  alarm_description = "Alarm when EC2 CPU exceeds 50 percent"

  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  threshold           = 50

  metric_name = "CPUUtilization"
  namespace   = "AWS/EC2"
  period      = 60
  statistic   = "Average"

  dimensions = {
    InstanceId = aws_instance.monitoring_ec2.id
  }

  treat_missing_data = "missing"

  tags = {
    Project = "Project3"
  }
}
