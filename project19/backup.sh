
#!/bin/bash
set -euo pipefail

PROJECT_DIR="$HOME/terraform-labs/project19"
BUCKET="project19-backup-nk-590507089733"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

aws s3 cp \
  "$PROJECT_DIR/logs/application.log" \
  "s3://$BUCKET/backups/application-$TIMESTAMP.log" \
  --region ap-southeast-1

echo "$(date) - Backup completed: application-$TIMESTAMP.log"
