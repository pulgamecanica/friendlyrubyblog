#!/bin/bash
set -e

echo "========================================="
echo "Setting up Monitoring & Health Checks"
echo "========================================="
echo ""

# Create a simple health check script on the server
cat > /tmp/health_check.sh << 'EOF'
#!/bin/bash

# Health check script for Friendly Ruby Blog
# Run this via cron every 5 minutes

DOMAIN="https://evil-penguin.com"
LOG_FILE="/var/log/friendlyrubyblog_health.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Check if the application is responding
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -m 10 "$DOMAIN" || echo "000")

if [ "$HTTP_CODE" = "200" ]; then
    echo "[$TIMESTAMP] ✓ Application is healthy (HTTP $HTTP_CODE)" >> "$LOG_FILE"
else
    echo "[$TIMESTAMP] ✗ Application is down or unhealthy (HTTP $HTTP_CODE)" >> "$LOG_FILE"
    # You can add alerting here (email, Slack, etc.)
fi

# Check Docker containers status
if ! docker ps | grep -q friendlyrubyblog-web; then
    echo "[$TIMESTAMP] ✗ Web container is not running!" >> "$LOG_FILE"
fi

if ! docker ps | grep -q friendlyrubyblog-db; then
    echo "[$TIMESTAMP] ✗ Database container is not running!" >> "$LOG_FILE"
fi

# Keep only last 1000 lines of log
tail -n 1000 "$LOG_FILE" > "$LOG_FILE.tmp" && mv "$LOG_FILE.tmp" "$LOG_FILE"
EOF

echo "Uploading health check script to server..."
scp /tmp/health_check.sh ssh_pt:/tmp/health_check.sh

echo "Installing health check on server..."
ssh ssh_pt bash << 'REMOTE_SCRIPT'
set -e

# Move health check script to proper location
sudo mv /tmp/health_check.sh /usr/local/bin/friendlyrubyblog_health_check.sh
sudo chmod +x /usr/local/bin/friendlyrubyblog_health_check.sh

# Create log directory if it doesn't exist
sudo touch /var/log/friendlyrubyblog_health.log
sudo chmod 666 /var/log/friendlyrubyblog_health.log

# Add to crontab (every 5 minutes)
(crontab -l 2>/dev/null | grep -v friendlyrubyblog_health_check; echo "*/5 * * * * /usr/local/bin/friendlyrubyblog_health_check.sh") | crontab -

echo "✓ Health check installed and scheduled (runs every 5 minutes)"
echo "✓ Logs will be written to /var/log/friendlyrubyblog_health.log"

REMOTE_SCRIPT

rm /tmp/health_check.sh

echo ""
echo "========================================="
echo "Monitoring Setup Complete!"
echo "========================================="
echo ""
echo "Health checks will run every 5 minutes"
echo "View logs: ssh ssh_pt 'tail -f /var/log/friendlyrubyblog_health.log'"
echo ""
echo "Useful monitoring commands:"
echo "  kamal app logs           # View application logs"
echo "  kamal app details        # View container status"
echo "  kamal accessory logs db  # View database logs"
echo "  kamal proxy logs         # View proxy/SSL logs"
echo ""
