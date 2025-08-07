#!/bin/bash

# ΛFFiNE Security Hardening Script

echo "🔒 Applying security hardening..."

# Install UFW firewall
apt install -y ufw

# Configure firewall
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable

# Install fail2ban
apt install -y fail2ban

# Create fail2ban configuration for SSH
cat > /etc/fail2ban/jail.local << EOF
[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 3600
EOF

# Start and enable fail2ban
systemctl start fail2ban
systemctl enable fail2ban

# Secure SSH configuration
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
systemctl restart ssh

# Set up automatic security updates
apt install -y unattended-upgrades
echo 'Unattended-Upgrade::Automatic-Reboot "false";' > /etc/apt/apt.conf.d/50unattended-upgrades

echo "✅ Security hardening completed"
echo "⚠️  Note: Password authentication is now disabled"
echo "   Make sure you have SSH key access configured!"
