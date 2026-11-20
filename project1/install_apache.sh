#!/bin/bash
set -eux

# Install Apache
dnf install -y httpd

# Create a sample webpage
cat > /var/www/html/index.html <<'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Terraform Project 1</title>
</head>
<body>
    <h1>Welcome to My Terraform Web Server!</h1>
    <h2>Project 1 Completed Successfully</h2>
    <p>Running on Amazon Linux 2023 with Apache.</p>
    <p>Infrastructure created using Terraform.</p>
</body>
</html>
EOF

# Enable and start Apache
systemctl enable --now httpd
