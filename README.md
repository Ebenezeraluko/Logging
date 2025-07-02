# Logging
Logging systems

Routing Container Logs Through Nginx

**Steps**:
1. Create a setup script: check the script for sub-steps
2. Create a log aggregator docker-compose.yml
3. Then follow implementation steps below

## Key Components:
1. **Nginx Configuration**: Serves logs from `/var/log/containers/` with basic authentication and security headers
2. **Container Logging Setup**: 
    - Syslog-based logging (cleaner approach)
3. **Log Rotation**: Configured to keep logs for 7 days with daily rotation
4. **Security**: Basic auth protection and file type restrictions

## Implementation Steps:
1. **Run the setup script** to create directories, auth file, and services
2. **Choose your logging approach**:
    - Use the syslog approach (recommended for production)
3. **Add the nginx configuration** to your server block
4. **Test and reload nginx**
