#!/bin/bash
set -euo pipefail

# ── System update ────────────────────────────────────────────────────
yum update -y

# ── Install essentials ───────────────────────────────────────────────
yum install -y \
  amazon-cloudwatch-agent \
  aws-cli \
  git \
  curl \
  htop

# ── Install Docker ───────────────────────────────────────────────────
amazon-linux-extras install docker -y
systemctl enable docker
systemctl start docker
usermod -aG docker ec2-user

# ── Set hostname ─────────────────────────────────────────────────────
hostnamectl set-hostname "${project}-${environment}-app"

# ── Tag instance with startup time ───────────────────────────────────
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)
aws ec2 create-tags \
  --resources "$INSTANCE_ID" \
  --tags Key=StartedAt,Value="$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --region "$REGION" || true

echo "Bootstrap complete for ${project}-${environment}" >> /var/log/bootstrap.log
