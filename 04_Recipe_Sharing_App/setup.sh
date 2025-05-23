#!/bin/bash
set -e

# Install necessary packages
apt update -y
apt install -y python3 python3-pip python3-venv nginx jq

# Set up app directory
mkdir -p /home/ubuntu/RecipeSharingApp
cd /home/ubuntu/RecipeSharingApp

# Download app files
python3 -m venv venv
source venv/bin/activate
FOLDER="https://raw.githubusercontent.com/shahinam2/AWS-DevOps-Projects/refs/heads/main/04_Recipe_Sharing_App/backend"
wget ${FOLDER}/requirements.txt
wget ${FOLDER}/main.py
# Get the token, find the region and replace in main.py file
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
sed -i "s/SELECTED_REGION/$(curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/dynamic/instance-identity/document | jq -r '.region')/g" main.py
pip3 install -r requirements.txt

# Fix permissions
chown -R ubuntu:ubuntu /home/ubuntu/RecipeSharingApp

# Create systemd unit for Uvicorn
cat <<EOF > /etc/systemd/system/RecipeSharingApp.service
[Unit]
Description=Uvicorn instance for Recipe Sharing app
After=network.target

[Service]
User=ubuntu
Group=ubuntu
WorkingDirectory=/home/ubuntu/RecipeSharingApp
ExecStart=/home/ubuntu/RecipeSharingApp/venv/bin/python3 -m uvicorn main:app --host 127.0.0.1 --port 8000
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Enable and start Uvicorn as a service
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
systemctl restart nginx

echo "Setup script executed successfully"