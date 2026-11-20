output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.monitoring_ec2.id
}

output "public_ip" {
  description = "EC2 public IP address"
  value       = aws_instance.monitoring_ec2.public_ip
}

output "alarm_name" {
  description = "CloudWatch alarm name"
  value       = aws_cloudwatch_metric_alarm.cpu_alarm.alarm_name
}
