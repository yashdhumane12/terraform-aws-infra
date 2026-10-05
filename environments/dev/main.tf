terraform {
  required_version = ">= 1.7.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.40"
    }
  }

  # Remote state in S3 — run bootstrap/ first to create this bucket
  backend "s3" {
    bucket         = "terraform-aws-infra-tfstate"
    key            = "dev/terraform.tfstate"
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
  environment = "dev"
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
  vpc_cidr             = "10.0.0.0/16"
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]
  availability_zones   = ["${var.aws_region}a", "${var.aws_region}b"]
  common_tags          = local.common_tags
}

# ── EC2 ──────────────────────────────────────────────────────────────
module "ec2" {
  source = "../../modules/ec2"

  project        = var.project
  environment    = local.environment
  vpc_id         = module.vpc.vpc_id
  subnet_ids     = module.vpc.public_subnet_ids
  ami_id         = var.ami_id
  instance_type  = "t3.micro" # Dev: small instance
  instance_count = 1
  key_name       = var.key_name
  common_tags    = local.common_tags
}

# ── RDS ──────────────────────────────────────────────────────────────
module "rds" {
  source = "../../modules/rds"

  project               = var.project
  environment           = local.environment
  vpc_id                = module.vpc.vpc_id
  subnet_ids            = module.vpc.private_subnet_ids
  ec2_security_group_id = module.ec2.security_group_id
  instance_class        = "db.t3.micro"
  allocated_storage     = 20
  db_name               = "appdb"
  db_username           = var.db_username
  db_password           = var.db_password
  multi_az              = false # Dev: no multi-AZ to save cost
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
