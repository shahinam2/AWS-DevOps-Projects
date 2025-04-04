#!/bin/bash
set -euxo pipefail

# Root-level setup
yum update -y
yum install nginx -y

# Prepare app directory
mkdir -p /home/ec2-user/roman-numerals-converter/templates
mkdir -p /home/ec2-user/roman-numerals-converter/static
chown -R ec2-user:ec2-user /home/ec2-user

# Run user-specific logic as ec2-user (via heredoc)
su - ec2-user -s /bin/bash <<'EOF'
set -euxo pipefail

# Define working directory
cd /home/ec2-user/roman-numerals-converter

# Ensure local bin is in PATH
export PATH="$HOME/.local/bin:$PATH"

# Install uv
curl -LsSf https://astral.sh/uv/install.sh | bash

# Setup venv and activate
uv venv
source .venv/bin/activate

# Install Flask and Gunicorn
uv init .
uv add flask gunicorn

# Download app files
FOLDER="https://raw.githubusercontent.com/shahinam2/AWS-DevOps-Projects/refs/heads/main/02_Roman_Numerals_Converter_Application"
wget -P templates ${FOLDER}/templates/index.html
wget -P templates ${FOLDER}/templates/result.html
wget -P static ${FOLDER}/static/applogo.png
wget ${FOLDER}/app.py
EOF


# Create systemd unit for Gunicorn
cat <<EOF > /etc/systemd/system/roman-numerals-converter.service
[Unit]
Description=Gunicorn instance for Roman Numerals app
After=network.target

[Service]
User=ec2-user
Group=ec2-user
WorkingDirectory=/home/ec2-user/roman-numerals-converter
ExecStart=/home/ec2-user/roman-numerals-converter/.venv/bin/gunicorn -b 127.0.0.1:8000 app:app
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Enable and start Gunicorn
chmod 644 /etc/systemd/system/roman-numerals-converter.service
systemctl daemon-reload
systemctl enable roman-numerals-converter
systemctl start roman-numerals-converter

# Configure Nginx reverse proxy
cat <<EOF > /etc/nginx/conf.d/roman-numerals.conf
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

# Start and enable Nginx
systemctl start nginx
systemctl enable nginx