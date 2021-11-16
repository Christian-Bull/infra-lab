#! /bin/bash
set -xe

# startup script run on all ec2 instances created

sudo apt update

sudo apt install nginx -y

sudo systemctl enable nginx
sudo systemctl restart nginx