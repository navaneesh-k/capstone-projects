
terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}

resource "local_file" "webpage" {
  filename = "${abspath(path.module)}/website/index.html"

  content = <<-EOF
    <html>
      <body>
        <h1>Project 24 - Manual Chaos Test</h1>
        <p>Application is running successfully!</p>
      </body>
    </html>
  EOF
}

resource "local_file" "service" {
  filename = "${abspath(path.module)}/project24-nk.service"

  content = <<-EOF
    [Unit]
    Description=Project 24 Chaos Test Web Service
    After=network.target

    [Service]
    Type=simple
    User=clouduser
    WorkingDirectory=${abspath(path.module)}/website
    ExecStart=/usr/bin/python3 -m http.server 8024 --bind 127.0.0.1
    Restart=no

    [Install]
    WantedBy=multi-user.target
  EOF
}

output "application_url" {
  value = "http://127.0.0.1:8024"
}
