#!/bin/bash
# n8n-auto-install.sh (Complete Version)
# Usage: sudo ./n8n-auto-install.sh yourdomain.com n8n-subdomain

# Check sudo privileges
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root"
    exit
fi

# Input parameters
BASE_DOMAIN="$1"
SUBDOMAIN="$2"
FULL_DOMAIN="${SUBDOMAIN}.${BASE_DOMAIN}"

# Update system
echo "Updating system..."
dnf update -y

# Install requirements
echo "Installing dependencies..."
dnf install -y nodejs npm firewalld httpd mod_ssl mod_proxy_html certbot python3-certbot-apache

# Configure Apache modules
echo "Configuring Apache modules..."
cat > /etc/httpd/conf.modules.d/00-n8n-proxy.conf <<EOF
LoadModule proxy_module modules/mod_proxy.so
LoadModule proxy_http_module modules/mod_proxy_http.so
LoadModule proxy_wstunnel_module modules/mod_proxy_wstunnel.so
LoadModule rewrite_module modules/mod_rewrite.so
LoadModule ssl_module modules/mod_ssl.so
EOF

# Verify modules
echo "Enabled Apache modules:"
httpd -M | grep -E 'proxy|rewrite|ssl'

# Configure firewall
echo "Configuring firewall..."
systemctl enable --now firewalld
firewall-cmd --permanent --add-service={http,https}
firewall-cmd --permanent --add-port=5678/tcp
firewall-cmd --reload

# Install n8n
echo "Installing n8n..."
npm install n8n -g

# Create systemd service
echo "Creating n8n service..."
cat > /etc/systemd/system/n8n.service <<EOF
[Unit]
Description=n8n Service
Documentation=https://docs.n8n.io
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/bin/n8n start
Environment=N8N_HOST=0.0.0.0
Environment=N8N_PORT=5678
Environment=WEBHOOK_URL=https://${FULL_DOMAIN}
Environment=N8N_PROTOCOL=https
Environment=N8N_RUNNERS_ENABLED=true
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd
systemctl daemon-reload
systemctl enable --now n8n

# Configure Apache
echo "Creating Apache configuration..."
cat > /etc/httpd/conf.d/${SUBDOMAIN}.conf <<EOF
<VirtualHost *:80>
    ServerName ${FULL_DOMAIN}
    Redirect permanent / https://${FULL_DOMAIN}/
</VirtualHost>

<VirtualHost *:443>
    ServerName ${FULL_DOMAIN}
    
    # SSL Configuration
    SSLEngine on
    SSLCertificateFile /etc/letsencrypt/live/${FULL_DOMAIN}/fullchain.pem
    SSLCertificateKeyFile /etc/letsencrypt/live/${FULL_DOMAIN}/privkey.pem

    # WebSocket Support
    RewriteEngine On
    RewriteCond %{HTTP:Upgrade} =websocket [NC]
    RewriteRule /(.*) ws://localhost:5678/\$1 [P,L]

    # Reverse Proxy
    ProxyPreserveHost On
    ProxyPass / http://localhost:5678/
    ProxyPassReverse / http://localhost:5678/
    
    # Security Headers
    Header always set Content-Security-Policy "default-src 'self' 'unsafe-inline' 'unsafe-eval' https:"
    Header always set X-Content-Type-Options "nosniff"
    Header always set X-Frame-Options "SAMEORIGIN"
    
    ErrorLog /var/log/httpd/${SUBDOMAIN}_error.log
    CustomLog /var/log/httpd/${SUBDOMAIN}_access.log combined
</VirtualHost>
EOF

# Obtain SSL certificate
echo "Getting SSL certificate..."
certbot --apache --non-interactive --agree-tos -m admin@${BASE_DOMAIN} -d ${FULL_DOMAIN}

# SELinux configuration
echo "Configuring SELinux..."
setsebool -P httpd_can_network_connect 1

# Restart services
echo "Finalizing setup..."
systemctl restart httpd
systemctl restart n8n

echo "Installation complete!"
echo "Access n8n at: https://${FULL_DOMAIN}"
echo "WebSocket test command: curl -i -N -H 'Connection: Upgrade' -H 'Upgrade: websocket' -H 'Host: ${FULL_DOMAIN}' https://${FULL_DOMAIN}/ws"