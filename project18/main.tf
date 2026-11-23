
terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}

resource "local_file" "deployment" {
  filename = "${path.module}/deployment.txt"

  content = <<-EOF
    Project 18 - GitOps Infrastructure Deployment
    Status: Successfully deployed
    Managed by: Terraform
    Triggered by: GitHub Actions
    Environment: Production
  EOF
}

output "deployment_status" {
  value = "GitOps deployment completed successfully"
}
