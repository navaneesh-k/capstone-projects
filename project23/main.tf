
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

resource "aws_s3_bucket" "demo" {
  bucket        = "project23-iam-demo-nk-590507089733"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "demo" {
  bucket = aws_s3_bucket.demo.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_object" "test" {
  bucket  = aws_s3_bucket.demo.id
  key     = "test.txt"
  content = "Project 23 - IAM role based S3 access successful!"
}

resource "aws_iam_role" "ec2_role" {
  name = "project23-ec2-s3-role-nk"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "s3_access" {
  name = "project23-s3-access-nk"
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:ListBucket"]
        Resource = aws_s3_bucket.demo.arn
      },
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject"]
        Resource = "${aws_s3_bucket.demo.arn}/*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "profile" {
  name = "project23-profile-nk"
  role = aws_iam_role.ec2_role.name
}

resource "aws_vpc" "main" {
  cidr_block           = "10.23.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "project23-vpc-nk"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.23.1.0/24"
  availability_zone       = "ap-southeast-1a"
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "ec2" {
  name   = "project23-ec2-sg-nk"
  vpc_id = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

resource "aws_instance" "demo" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.ec2.id]
  iam_instance_profile   = aws_iam_instance_profile.profile.name

  metadata_options {
    http_tokens = "required"
  }

  user_data = <<-EOF
    #!/bin/bash
    exec > >(tee /var/log/project23-test.log /dev/console) 2>&1

    export AWS_DEFAULT_REGION=ap-southeast-1
    export AWS_PAGER=""

    echo "===== PROJECT 23 IAM ROLE TEST ====="

    echo "Checking IAM identity:"
    aws sts get-caller-identity

    echo "Listing S3 objects:"
    aws s3 ls s3://${aws_s3_bucket.demo.id}/

    echo "Reading S3 object:"
    aws s3 cp s3://${aws_s3_bucket.demo.id}/test.txt -

    echo ""
    echo "===== PROJECT 23 TEST END ====="
  EOF

  depends_on = [
    aws_iam_role_policy.s3_access,
    aws_s3_object.test,
    aws_s3_bucket_public_access_block.demo,
    aws_route_table_association.public
  ]

  tags = {
    Name = "project23-ec2-nk"
  }
}

output "instance_id" {
  value = aws_instance.demo.id
}

output "bucket_name" {
  value = aws_s3_bucket.demo.id
}

output "iam_role" {
  value = aws_iam_role.ec2_role.name
}
