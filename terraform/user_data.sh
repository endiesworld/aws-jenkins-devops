#!/bin/bash
set -euo pipefail

# Log to both console and file for post-boot debugging
exec > >(tee -a /var/log/user-data.log | logger -t user-data -s 2>/dev/console) 2>&1

echo "[user-data] Starting bootstrap for app host"

# Keep OS up to date; install docker + awscli + ssm agent
yum update -y
yum install -y docker aws-cli amazon-ssm-agent

# Enable + start daemons
systemctl enable --now docker
systemctl enable --now amazon-ssm-agent

# Allow ec2-user to run docker without sudo
if id ec2-user &>/dev/null; then
  usermod -aG docker ec2-user || true
fi

# Install Docker Compose v2 plugin
sudo curl -SL "https://github.com/docker/compose/releases/download/v2.39.2/docker-compose-linux-x86_64" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

echo "[user-data] Docker version: $(docker --version || true)"
echo "[user-data] Docker Compose version: $(docker compose version || true)"

# Simple health check
sleep 5
docker ps || true

echo "[user-data] Bootstrap complete"
