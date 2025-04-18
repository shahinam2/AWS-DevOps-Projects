#!/bin/bash
set -e

# Install necessary packages
apt update -y
sudo apt install -y python3 python3-pip python3-virtualenv nginx jq

# Get the token and 
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
SELECTED_REGION=$(sed -i "s/SELECTED_REGION/$(curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/dynamic/instance-identity/document | jq -r '.region')/g")

# Set up app directory
mkdir -p /home/ubuntu/RecipeSharingApp
cd /home/ubuntu/RecipeSharingApp

# Download app files
python3 -m venv venv
source venv/bin/activate
FOLDER="https://raw.githubusercontent.com/shahinam2/AWS-DevOps-Projects/refs/heads/main/04_Recipe_Sharing_App/backend"
wget ${FOLDER}/requirements.txt
wget ${FOLDER}/main.py
pip3 install -r requirements.txt

# Fix permissions
chown -R ubuntu:ubuntu /home/ubuntu/RecipeSharingApp

# Create systemd unit for Gunicorn
cat <<EOF > /etc/systemd/system/RecipeSharingApp.service
[Unit]
Description=Gunicorn instance for Recipe Sharing app
After=network.target

[Service]
User=ubuntu
Group=ubuntu
WorkingDirectory=/home/ubuntu/RecipeSharingApp
ExecStart=/home/ubuntu/RecipeSharingApp/venv/bin/gunicorn -b 127.0.0.1:8000 $SELECTED_REGION main:app
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Enable and start Gunicorn
chmod 644 /etc/systemd/system/RecipeSharingApp.service
systemctl daemon-reload
systemctl enable RecipeSharingApp
systemctl start RecipeSharingApp

# Configure Nginx reverse proxy
cat <<EOF > /etc/nginx/conf.d/RecipeSharingApp.conf
server {
    listen 80;
    server_name ~.;

    location / {
        proxy_pass http://127.0.0.1:8000;
    }
}
EOF

# Start and enable Nginx
systemctl start nginx
systemctl enable nginx