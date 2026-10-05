# ── Security Group ───────────────────────────────────────────────────
resource "aws_security_group" "ec2" {
  name        = "${var.project}-${var.environment}-ec2-sg"
  description = "Security group for EC2 instances"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidrs
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, {
    Name = "${var.project}-${var.environment}-ec2-sg"
  })
}

# ── IAM Role for EC2 (SSM access) ────────────────────────────────────
resource "aws_iam_role" "ec2" {
  name = "${var.project}-${var.environment}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })

  tags = var.common_tags
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "cloudwatch" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "ec2" {
  name = "${var.project}-${var.environment}-ec2-profile"
  role = aws_iam_role.ec2.name
}

# ── EC2 Instance ─────────────────────────────────────────────────────
resource "aws_instance" "app" {
  count                  = var.instance_count
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_ids[count.index % length(var.subnet_ids)]
  vpc_security_group_ids = [aws_security_group.ec2.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2.name
  key_name               = var.key_name

  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.root_volume_size
    encrypted             = true
    delete_on_termination = true
  }

  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    project     = var.project
    environment = var.environment
  }))

  metadata_options {
    http_tokens = "required"   # Enforce IMDSv2 for security
  }

  tags = merge(var.common_tags, {
    Name = "${var.project}-${var.environment}-app-${count.index + 1}"
  })

  lifecycle {
    create_before_destroy = true
  }
}
