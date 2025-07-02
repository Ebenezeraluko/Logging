#!/bin/bash

# Setup script for nginx log access
# Run as root or with sudo

set -e

echo "Setting up nginx log access for containerized apps..."

# Create log directory structure
mkdir -p /var/log/containers
chmod 755 /var/log/containers

# Create nginx auth file (you'll need to set password)
echo "Creating nginx auth file..."
read -p "Enter username for log access: " username
htpasswd -c /etc/nginx/.htpasswd "$username"

# Create logrotate configuration
cat > /etc/logrotate.d/docker-syslog << 'EOF'
/var/log/containers/*.log {
    daily
    compress
    delaycompress
    missingok
    notifempty
    dateext
    dateformat -%Y%m%d
    create 644 syslog syslog
    postrotate
    	systemctl reload rsyslog
    	systemctl reload nginx
    endscript
}
EOF

# Create a script to aggregate container logs
cat > /usr/local/bin/aggregate-container-logs.sh << 'EOF'
#!/bin/bash

LOG_BASE_DIR="/var/log/containers"
CONTAINERS=("pruvia-p2p-admin-fe" "pruvia_loan_app" "pruvia-client")

for container in "${CONTAINERS[@]}"; do
    if docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
        # Create container-specific directory
        CONTAINER_LOG_DIR="$LOG_BASE_DIR/$container"
        mkdir -p "$CONTAINER_LOG_DIR"

        # Use date-based log files
        LOG_FILE="$CONTAINER_LOG_DIR/$container-$(date '+%Y-%m-%d').log"

        # Get logs from last minute and append to daily log file
        docker logs "$container" --since 1m 2>&1 | \
        while IFS= read -r line; do
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] $line" >> "$LOG_FILE"
        done
    fi
done
EOF

chmod +x /usr/local/bin/aggregate-container-logs.sh

# Create systemd service for log aggregation
cat > /etc/systemd/system/container-log-aggregator.service << 'EOF'
[Unit]
Description=Container Log Aggregator
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
ExecStart=/usr/local/bin/aggregate-container-logs.sh
User=root

[Install]
WantedBy=multi-user.target
EOF

# Create systemd timer for log aggregation
cat > /etc/systemd/system/container-log-aggregator.timer << 'EOF'
[Unit]
Description=Run Container Log Aggregator every minute
Requires=container-log-aggregator.service

[Timer]
OnCalendar=*:*:00
Persistent=true

[Install]
WantedBy=timers.target
EOF

# Enable and start services
systemctl daemon-reload
systemctl enable container-log-aggregator.timer
systemctl start container-log-aggregator.timer

echo "Setup complete!"
echo "1. Add the nginx configuration to your server block"
echo "2. Test nginx configuration: nginx -t"
echo "3. Reload nginx: systemctl reload nginx"
echo "4. Access logs at: http://your-domain/app-logs/"
echo "5. Logs will be rotated daily and kept for 7 days"
