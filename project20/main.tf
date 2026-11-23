
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
  cidr_block           = "10.20.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "project20-vpc-nk"
  }
}

# Two public subnets in different AZs
resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.20.${count.index + 1}.0/24"
  availability_zone       = ["ap-southeast-1a", "ap-southeast-1b"][count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "project20-subnet-${count.index + 1}-nk"
  }
}

# Internet gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "project20-igw-nk"
  }
}

# Public routing
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "project20-route-nk"
  }
}

resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# ALB security group
resource "aws_security_group" "alb" {
  name   = "project20-alb-sg-nk"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "project20-alb-sg-nk"
  }
}

# EC2 security group
# Only ALB can access the web servers
resource "aws_security_group" "web" {
  name   = "project20-web-sg-nk"
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

  tags = {
    Name = "project20-web-sg-nk"
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
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Two EC2 web servers
resource "aws_instance" "web" {
  count                  = 2
  ami                    = data.aws_ami.linux.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public[count.index].id
  vpc_security_group_ids = [aws_security_group.web.id]

  user_data = <<-EOF
    #!/bin/bash
    dnf install -y httpd
    systemctl enable --now httpd

    cat > /var/www/html/index.html <<'HTML'
    <html>
      <head>
        <title>Project 20 Load Balancing</title>
      </head>
      <body>
        <h1>Project 20 - Load Balanced Application</h1>
        <h2>Response from EC2 Server ${count.index + 1}</h2>
        <p>Application Load Balancer is working!</p>
      </body>
    </html>
    HTML
  EOF

  depends_on = [
    aws_route_table_association.public
  ]

  tags = {
    Name = "project20-ec2-${count.index + 1}-nk"
  }
}

# Application Load Balancer
resource "aws_lb" "main" {
  name               = "project20-alb-nk"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id

  tags = {
    Name = "project20-alb-nk"
  }
}

# Target group with health checks
resource "aws_lb_target_group" "web" {
  name     = "project20-tg-nk"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    path                = "/"
    protocol            = "HTTP"
    port                = "traffic-port"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 30
    timeout             = 5
    matcher             = "200"
  }

  tags = {
    Name = "project20-tg-nk"
  }
}

# Register both EC2 instances
resource "aws_lb_target_group_attachment" "web" {
  count            = 2
  target_group_arn = aws_lb_target_group.web.arn
  target_id        = aws_instance.web[count.index].id
  port             = 80
}

# HTTP listener
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

# Outputs
output "alb_url" {
  value = "http://${aws_lb.main.dns_name}"
}

output "target_group_arn" {
  value = aws_lb_target_group.web.arn
}

output "ec2_instance_ids" {
  value = aws_instance.web[*].id
}
