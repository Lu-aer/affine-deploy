#!/bin/bash

# Optional SSL setup with Let's Encrypt
# Usage: ./ssl-setup.sh your-domain.com

if [ $# -eq 0 ]; then
    echo "Usage: $0 <domain-name>"
    exit 1
fi

DOMAIN=$1

echo "🔐 Setting up SSL for domain: ${DOMAIN}"

# Install certbot
apt install -y certbot python3-certbot-nginx nginx

# Create nginx config
cat > /etc/nginx/sites-available/affine << EOF
server {
    listen 80;
    server_name ${DOMAIN};
    
    location / {
        proxy_pass http://localhost:80;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

# Enable site
ln -s /etc/nginx/sites-available/affine /etc/nginx/sites-enabled/
nginx -t && systemctl reload nginx

# Get SSL certificate
certbot --nginx -d ${DOMAIN} --non-interactive --agree-tos -m admin@${DOMAIN}

echo "✅ SSL setup completed for ${DOMAIN}"
