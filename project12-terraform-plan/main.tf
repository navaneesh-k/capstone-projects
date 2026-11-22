terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}

provider "local" {}

resource "local_file" "infrastructure" {
  filename = "${path.module}/project12-nk.txt"

  content = <<-EOT
    Project: Infrastructure CI Trigger
    Environment: Development
    Managed By: Terraform
    Version: 1.0
  EOT
}
