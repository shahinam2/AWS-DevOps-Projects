#!/bin/bash
# Export the Secret ARN as an environment variable
echo "export DB_SECRET_ARN='{{resolve:secretsmanager:${DBCredential}}}'" >> /etc/environment
source /etc/environment

# Install necessary packages
yum update -y
yum install python3-pip nginx -y

# Set up app directory
mkdir -p /home/ec2-user/Email_Database/templates
mkdir -p /home/ec2-user/Email_Database/static
cd /home/ec2-user/Email_Database

# Download app files
python3 -m venv venv
source venv/bin/activate
pip3 install -r requirements.txt
FOLDER="https://raw.githubusercontent.com/shahinam2/AWS-DevOps-Projects/refs/heads/main/03_Email_Database"
wget -P templates ${FOLDER}/templates/index.html
wget -P templates ${FOLDER}/static/style.css
wget -P static ${FOLDER}/static/applogo.png
wget ${FOLDER}/requirements.txt
wget ${FOLDER}/app.py

# Fix permissions
chown -R ec2-user:ec2-user /home/ec2-user/Email_Database

# Create systemd unit for Gunicorn
cat <<EOF > /etc/systemd/system/Email_Database.service
[Unit]
Description=Gunicorn instance for Email Database app
After=network.target

[Service]
User=ec2-user
Group=ec2-user
WorkingDirectory=/home/ec2-user/Email_Database
ExecStart=/home/ec2-user/Email_Database/venv/bin/gunicorn -b 127.0.0.1:8000 app:app
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Enable and start Gunicorn
chmod 644 /etc/systemd/system/Email_Database.service
systemctl daemon-reload
systemctl enable Email_Database
systemctl start Email_Database

# Configure Nginx reverse proxy
cat <<EOF > /etc/nginx/conf.d/Email_Database.conf
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