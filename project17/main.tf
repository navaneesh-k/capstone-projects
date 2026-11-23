
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

# VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.17.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "project17-vpc-nk"
  }
}

# Public subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.17.1.0/24"
  availability_zone       = "ap-southeast-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "project17-subnet-nk"
  }
}

# Internet gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "project17-igw-nk"
  }
}

# Route table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "project17-route-nk"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# EC2 security group - outbound only
resource "aws_security_group" "ec2" {
  name   = "project17-sg-nk"
  vpc_id = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "project17-sg-nk"
  }
}

# IAM role for CloudWatch Agent
resource "aws_iam_role" "cloudwatch" {
  name = "project17-cloudwatch-role-nk"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "project17-cloudwatch-role-nk"
  }
}

# Attach CloudWatch Agent permissions
resource "aws_iam_role_policy_attachment" "cloudwatch" {
  role       = aws_iam_role.cloudwatch.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Instance profile
resource "aws_iam_instance_profile" "cloudwatch" {
  name = "project17-profile-nk"
  role = aws_iam_role.cloudwatch.name
}

# CloudWatch log group
resource "aws_cloudwatch_log_group" "logs" {
  name              = "/project17/ec2-logs-nk"
  retention_in_days = 7

  tags = {
    Name = "project17-logs-nk"
  }
}

# Amazon Linux 2023 AMI
data "aws_ami" "linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

# EC2 instance with automatic log forwarding
resource "aws_instance" "web" {
  ami                    = data.aws_ami.linux.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.ec2.id]
  iam_instance_profile   = aws_iam_instance_profile.cloudwatch.name

  user_data = <<-EOF
    #!/bin/bash
    set -euxo pipefail

    # Install system logging and CloudWatch Agent
    dnf install -y rsyslog amazon-cloudwatch-agent

    # Enable Linux system logging
    systemctl enable --now rsyslog

    # Create CloudWatch Agent configuration
    mkdir -p /opt/aws/amazon-cloudwatch-agent/etc

    cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json <<'CONFIG'
    {
      "agent": {
        "run_as_user": "root"
      },
      "logs": {
        "logs_collected": {
          "files": {
            "collect_list": [
              {
                "file_path": "/var/log/messages",
                "log_group_name": "/project17/ec2-logs-nk",
                "log_stream_name": "{instance_id}",
                "timezone": "UTC"
              }
            ]
          }
        }
      }
    }
    CONFIG

    # Start CloudWatch Agent
    /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
      -a fetch-config \
      -m ec2 \
      -s \
      -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json

    # Generate test log messages
    logger "Project 17 NK - CloudWatch log forwarding successful"

    for i in 1 2 3 4 5
    do
      logger "Project 17 NK - Test log message $i"
      sleep 2
    done
  EOF

  depends_on = [
    aws_iam_role_policy_attachment.cloudwatch,
    aws_cloudwatch_log_group.logs,
    aws_route_table_association.public
  ]

  tags = {
    Name = "project17-ec2-nk"
  }
}

# Outputs
output "instance_id" {
  value = aws_instance.web.id
}

output "log_group_name" {
  value = aws_cloudwatch_log_group.logs.name
}

output "region" {
  value = "ap-southeast-1"
}
