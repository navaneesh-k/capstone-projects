output "iam_user_name" {
  description = "Created IAM username"
  value       = aws_iam_user.s3_reader.name
}

output "iam_user_arn" {
  description = "IAM user ARN"
  value       = aws_iam_user.s3_reader.arn
}

output "policy_arn" {
  description = "S3 read policy ARN"
  value       = aws_iam_policy.s3_read_policy.arn
}
