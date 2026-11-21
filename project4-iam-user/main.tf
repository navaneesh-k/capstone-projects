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

# Create IAM user
resource "aws_iam_user" "s3_reader" {
  name = var.iam_user_name

  tags = {
    Name    = "Project4-S3-Reader"
    Project = "Project4"
  }
}

# Create IAM policy from variable
resource "aws_iam_policy" "s3_read_policy" {
  name        = "project4-s3-read-policy-nk"
  description = "Allows read-only access to S3"
  policy      = jsonencode(var.s3_policy)
}

# Attach policy to IAM user
resource "aws_iam_user_policy_attachment" "s3_read_attach" {
  user       = aws_iam_user.s3_reader.name
  policy_arn = aws_iam_policy.s3_read_policy.arn
}
