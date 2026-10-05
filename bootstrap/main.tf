# ── Bootstrap: Creates S3 bucket + DynamoDB table for Terraform remote state ──
# Run this ONCE before deploying any environment
# terraform init && terraform apply (uses local state)

terraform {
  required_version = ">= 1.7.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.40"
    }
  }
  # Bootstrap uses LOCAL state intentionally
}

provider "aws" {
  region = var.aws_region
}

# ── S3 bucket for Terraform state ────────────────────────────────────
resource "aws_s3_bucket" "tfstate" {
  bucket = var.state_bucket_name

  tags = {
    Name      = "Terraform State Bucket"
    ManagedBy = "Terraform"
  }
}

resource "aws_s3_bucket_versioning" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  rule {
    apply_server_side_encryption_by_default { sse_algorithm = "AES256" }
  }
}

resource "aws_s3_bucket_public_access_block" "tfstate" {
  bucket                  = aws_s3_bucket.tfstate.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ── DynamoDB table for state locking ─────────────────────────────────
resource "aws_dynamodb_table" "tfstate_lock" {
  name         = "terraform-state-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name      = "Terraform State Lock"
    ManagedBy = "Terraform"
  }
}

output "state_bucket" { value = aws_s3_bucket.tfstate.id }
output "lock_table"   { value = aws_dynamodb_table.tfstate_lock.name }
