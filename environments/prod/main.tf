terraform {
  required_version = ">= 1.7.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.40"
    }
  }

  backend "s3" {
    bucket         = "terraform-aws-infra-tfstate"
    key            = "prod/terraform.tfstate"
    region         = "ap-south-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}

locals {
  environment = "prod"
  common_tags = {
    Project     = var.project
    Environment = local.environment
    ManagedBy   = "Terraform"
    Owner       = "Yash Dhumane"
  }
}

# ── VPC ──────────────────────────────────────────────────────────────
module "vpc" {
  source = "../../modules/vpc"

  project              = var.project
  environment          = local.environment
  vpc_cidr             = "10.1.0.0/16"   # Different CIDR from dev
  public_subnet_cidrs  = ["10.1.1.0/24", "10.1.2.0/24"]
  private_subnet_cidrs = ["10.1.10.0/24", "10.1.11.0/24"]
  availability_zones   = ["${var.aws_region}a", "${var.aws_region}b"]
  common_tags          = local.common_tags
}

# ── EC2 ──────────────────────────────────────────────────────────────
module "ec2" {
  source = "../../modules/ec2"

  project           = var.project
  environment       = local.environment
  vpc_id            = module.vpc.vpc_id
  subnet_ids        = module.vpc.private_subnet_ids  # Prod: private subnet
  ami_id            = var.ami_id
  instance_type     = "t3.small"    # Prod: bigger instance
  instance_count    = 2             # Prod: 2 instances for HA
  key_name          = var.key_name
  allowed_ssh_cidrs = ["10.1.0.0/16"]  # Prod: only internal SSH
  root_volume_size  = 40
  common_tags       = local.common_tags
}

# ── RDS ──────────────────────────────────────────────────────────────
module "rds" {
  source = "../../modules/rds"

  project               = var.project
  environment           = local.environment
  vpc_id                = module.vpc.vpc_id
  subnet_ids            = module.vpc.private_subnet_ids
  ec2_security_group_id = module.ec2.security_group_id
  instance_class        = "db.t3.small"  # Prod: bigger DB
  allocated_storage     = 50
  db_name               = "appdb"
  db_username           = var.db_username
  db_password           = var.db_password
  multi_az              = true           # Prod: Multi-AZ for HA
  common_tags           = local.common_tags
}

# ── S3 ───────────────────────────────────────────────────────────────
module "s3_assets" {
  source = "../../modules/s3"

  project       = var.project
  environment   = local.environment
  bucket_suffix = "assets"
  common_tags   = local.common_tags
}

module "s3_backups" {
  source = "../../modules/s3"

  project       = var.project
  environment   = local.environment
  bucket_suffix = "backups"
  common_tags   = local.common_tags
}
