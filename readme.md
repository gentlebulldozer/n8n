# n8n Automated Installation Script for AlmaLinux

[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

A production-ready installation script for n8n workflow automation on AlmaLinux/RHEL systems with automatic SSL, WebSocket support, and Apache reverse proxy configuration.

Tested on Almalinux 8, 9

## Features

- 🚀 Single-command installation
- 🔒 Automatic Let's Encrypt SSL configuration
- 🌐 Apache reverse proxy with WebSocket support
- 🔥 Systemd service integration
- 🛡️ SELinux and firewall pre-configuration
- 📈 Production-ready security headers
- 🔄 Automatic dependency management

## Prerequisites

- AlmaLinux 8/9 or RHEL-compatible system
- Root/sudo access
- Domain name with DNS A record pointing to your server
- Ports 80/443 open in network/firewall

## Installation

1. **Download the script**
wget https://raw.githubusercontent.com/gentlebulldozer/n8n/refs/heads/main/n8n-auto-install.sh

2. **Make executable**
chmod +x n8n-auto-install.sh

3. **Run the installer**
sudo ./n8n-auto-install.sh yourdomain.com subdomain
Example:
sudo ./n8n-auto-install.sh example.com n8n

## Post-Installation
1. Verify services
systemctl status n8n httpd

2. Test WebSocket connection
curl -i -N -H "Connection: Upgrade" -H "Upgrade: websocket" -H "Host: n8n.example.com" https://n8n.example.com/ws

3. Access n8n interface
https://n8n.example.com

## Cloudflare Users
If using Cloudflare:
1. Enable WebSockets in Network settings
2. Set SSL mode to Full (strict)
3. Disable "Always Use HTTPS" (handled by script)

# Update n8n
sudo npm update -g n8n
sudo systemctl restart n8n

# Update script
wget -O n8n-auto-install.sh https://raw.githubusercontent.com/gentlebulldozer/n8n/refs/heads/main/n8n-auto-install.sh

## Troubleshooting
Common Issues
SSL Certificate Errors
- Verify DNS propagation with dig +short n8n.example.com
- Check certificate exists: ls /etc/letsencrypt/live/n8n.example.com/

**WebSocket Connection Issues**
sudo tail -f /var/log/httpd/n8n_error.log
curl -I -N -H "Connection: Upgrade" -H "Upgrade: websocket" https://n8n.example.com

**Service Not Running**
sudo journalctl -u n8n -f
ss -tulpn | grep 5678

**Configuration options**
Edit /etc/systemd/system/n8n.service for:
- Custom ports
- Environment variables
- Resource limits

Edit /etc/httpd/conf.d/n8n.conf for:

- Custom headers
- Rate limiting
- Access restrictions

**Contributing**
Contributions welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Submit a PR with detailed description

## License
Apache 2.0 - See LICENSE for details

Maintained by GentleDozer | @GentleDozer | Professional Services Available