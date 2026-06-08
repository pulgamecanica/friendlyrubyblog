#!/bin/bash
set -e

echo "========================================="
echo "Setting up Monitoring & Health Checks"
echo "========================================="
echo ""

SERVER="friendlyrubyblog@165.232.74.204"

# Create a simple health check script locally, then ship it to the server.
# Everything lives under the deploy user's $HOME so no sudo is ever required.
cat > /tmp/health_check.sh << 'EOF'
#!/bin/bash

# Health check script for Friendly Ruby Blog
# Run this via cron every 5 minutes (user crontab, no sudo).

DOMAIN="https://165.232.74.204"
# Logs and state live under the user's home — no root-owned paths.
LOG_FILE="$HOME/.local/state/friendlyrubyblog/health.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Make sure the log directory exists (self-healing, no sudo).
mkdir -p "$(dirname "$LOG_FILE")"

# Check if the application is responding.
# -k: the endpoint is an IP over HTTPS, so skip cert-hostname verification.
HTTP_CODE=$(curl -sk -o /dev/null -w "%{http_code}" -m 10 "$DOMAIN" || echo "000")

if [ "$HTTP_CODE" = "200" ]; then
    echo "[$TIMESTAMP] ✓ Application is healthy (HTTP $HTTP_CODE)" >> "$LOG_FILE"
else
    echo "[$TIMESTAMP] ✗ Application is down or unhealthy (HTTP $HTTP_CODE)" >> "$LOG_FILE"
    # You can add alerting here (email, Slack, etc.)
fi

# Check Docker containers status (requires the user to be in the docker group).
if ! docker ps | grep -q friendlyrubyblog-web; then
    echo "[$TIMESTAMP] ✗ Web container is not running!" >> "$LOG_FILE"
fi

if ! docker ps | grep -q friendlyrubyblog-db; then
    echo "[$TIMESTAMP] ✗ Database container is not running!" >> "$LOG_FILE"
fi

# Keep only last 1000 lines of log.
tail -n 1000 "$LOG_FILE" > "$LOG_FILE.tmp" && mv "$LOG_FILE.tmp" "$LOG_FILE"
EOF

echo "Uploading health check script to server..."
scp /tmp/health_check.sh "$SERVER:/tmp/health_check.sh"

echo "Installing health check on server..."
ssh "$SERVER" bash << 'REMOTE_SCRIPT'
set -e

# User-owned locations — no sudo needed.
BIN_DIR="$HOME/.local/bin"
STATE_DIR="$HOME/.local/state/friendlyrubyblog"
SCRIPT_PATH="$BIN_DIR/friendlyrubyblog_health_check.sh"
LOG_FILE="$STATE_DIR/health.log"

mkdir -p "$BIN_DIR" "$STATE_DIR"

# Install the health check script into the user's bin.
mv /tmp/health_check.sh "$SCRIPT_PATH"
chmod +x "$SCRIPT_PATH"

# Create the log file (owned by this user, world-readable not required).
touch "$LOG_FILE"

# Add to the user crontab (every 5 minutes), replacing any prior entry.
(crontab -l 2>/dev/null | grep -v friendlyrubyblog_health_check; \
  echo "*/5 * * * * $SCRIPT_PATH") | crontab -

echo "✓ Health check installed at $SCRIPT_PATH"
echo "✓ Scheduled via user crontab (runs every 5 minutes, no sudo)"
echo "✓ Logs will be written to $LOG_FILE"

REMOTE_SCRIPT

rm /tmp/health_check.sh

echo ""
echo "========================================="
echo "Monitoring Setup Complete!"
echo "========================================="
echo ""
echo "Health checks will run every 5 minutes"
echo "View logs: ssh $SERVER 'tail -f ~/.local/state/friendlyrubyblog/health.log'"
echo ""
echo "Useful monitoring commands:"
echo "  kamal app logs           # View application logs"
echo "  kamal app details        # View container status"
echo "  kamal accessory logs db  # View database logs"
echo "  kamal proxy logs         # View proxy/SSL logs"
echo ""
