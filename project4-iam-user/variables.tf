variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "iam_user_name" {
  description = "IAM user name"
  type        = string
  default     = "project4-s3-reader-nk"
}

variable "s3_policy" {
  description = "S3 read-only IAM policy"
  type        = any

  default = {
    Version = "2012-10-17"

    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:ListAllMyBuckets"]
        Resource = ["*"]
      },
      {
        Effect   = "Allow"
        Action   = ["s3:ListBucket"]
        Resource = ["arn:aws:s3:::*"]
      },
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject"]
        Resource = ["arn:aws:s3:::*/*"]
      }
    ]
  }
}
