
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
    Managed by: Terraform
    Status: Successfully deployed through PR merge
    Triggered by: GitHub Actions
    Environment: Production
  EOF
}

output "deployment_status" {
  value = "GitOps deployment completed successfully"
}
