#!/bin/bash
yum update -y
yum install python3 python3-pip nginx wget -y

# Set up app directory
mkdir -p /home/ec2-user/roman-numerals-converter/templates
mkdir -p /home/ec2-user/roman-numerals-converter/static
cd /home/ec2-user/roman-numerals-converter

# Download app files
python3 -m venv venv
source venv/bin/activate
pip3 install flask gunicorn
FOLDER="https://raw.githubusercontent.com/shahinam2/AWS-DevOps-Projects/refs/heads/main/02_Roman_Numerals_Converter_Application"
wget -P templates ${FOLDER}/templates/index.html
wget -P templates ${FOLDER}/templates/result.html
wget -P static ${FOLDER}/static/applogo.png
wget ${FOLDER}/app.py

# Fix permissions
chown -R ec2-user:ec2-user /home/ec2-user/roman-numerals-converter

# Create systemd unit for Gunicorn
cat <<EOF > /etc/systemd/system/roman-numerals-converter.service
[Unit]
Description=Gunicorn instance for Roman Numerals app
After=network.target

[Service]
User=ec2-user
Group=ec2-user
WorkingDirectory=/home/ec2-user/roman-numerals-converter
ExecStart=/home/ec2-user/roman-numerals-converter/venv/bin/gunicorn -b 127.0.0.1:8000 app:app
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