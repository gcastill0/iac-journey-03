#!/usr/bin/bash
# File in /root/user-data.bash.tpl

# Install required packages one at a time

sudo apt update
sudo apt install git -y 
sudo apt install nginx -y

# This is a simple Web app to show that the deployment works.

sudo wget https://github.com/interrupt-software/happy-animals/archive/refs/tags/v1.0.1.tar.gz -P /home/ubuntu/
sudo chmod +x /home/ubuntu/v1.0.1.tar.gz
sudo tar xvfz /home/ubuntu/v1.0.1.tar.gz -C /var/www
sudo rm -fR /var/www/html
sudo mv /var/www/happy-animals-1.0.1 /var/www/html

# Show the Web app
sudo systemctl start nginx