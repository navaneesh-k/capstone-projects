
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
  cidr_block = "10.16.0.0/16"

  tags = {
    Name = "project16-vpc-nk"
  }
}

# Public subnets
resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.16.${count.index + 1}.0/24"
  availability_zone       = ["ap-southeast-1a", "ap-southeast-1b"][count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "project16-subnet-${count.index + 1}-nk"
  }
}

# Internet gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "project16-igw-nk"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
}

resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# ALB security group: HTTPS only
resource "aws_security_group" "alb" {
  name   = "project16-alb-sg-nk"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EC2 accepts HTTP only from ALB
resource "aws_security_group" "web" {
  name   = "project16-web-sg-nk"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Latest Amazon Linux 2023 AMI
data "aws_ami" "linux" {
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

# Web server
resource "aws_instance" "web" {
  ami                    = data.aws_ami.linux.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public[0].id
  vpc_security_group_ids = [aws_security_group.web.id]

  user_data = <<-EOF
    #!/bin/bash
    dnf install -y httpd
    systemctl enable --now httpd
    echo "<h1>Project 16 - HTTPS Enabled Successfully</h1><p>Secured using ALB and AWS ACM</p>" > /var/www/html/index.html
  EOF

  tags = {
    Name = "project16-web-nk"
  }
}

# Import self-signed certificate into ACM
resource "aws_acm_certificate" "cert" {
  private_key      = file("${path.module}/server.key")
  certificate_body = file("${path.module}/server.crt")

  tags = {
    Name = "project16-cert-nk"
  }
}

# Application Load Balancer
resource "aws_lb" "main" {
  name               = "project16-alb-nk"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id

  tags = {
    Name = "project16-alb-nk"
  }
}

# Target group
resource "aws_lb_target_group" "web" {
  name     = "project16-tg-nk"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path = "/"
  }
}

resource "aws_lb_target_group_attachment" "web" {
  target_group_arn = aws_lb_target_group.web.arn
  target_id        = aws_instance.web.id
  port             = 80
}

# HTTPS listener only (HTTP blocked)
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate.cert.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

output "https_url" {
  value = "https://${aws_lb.main.dns_name}"
}

output "http_url" {
  value = "http://${aws_lb.main.dns_name}"
}
