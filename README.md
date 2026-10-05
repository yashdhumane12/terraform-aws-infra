# 🏗️ Terraform AWS Infrastructure

Production-ready AWS infrastructure as code using Terraform — VPC, EC2, RDS (PostgreSQL), and S3 with separate dev/prod environments, remote state management, and automated CI/CD via GitHub Actions.

## 🏗️ Architecture

```
                    AWS Account
┌───────────────────────────────────────────────────────┐
│                                                       │
│   ┌─────────── VPC (10.0.0.0/16) ─────────────────┐  │
│   │                                               │  │
│   │  Public Subnets          Private Subnets      │  │
│   │  ┌──────────────┐       ┌──────────────────┐  │  │
│   │  │  EC2 (App)   │       │  RDS PostgreSQL   │  │  │
│   │  │  + IAM Role  │──────▶│  (Multi-AZ prod) │  │  │
│   │  └──────────────┘       └──────────────────┘  │  │
│   │         │                                     │  │
│   │  ┌──────▼──────┐                              │  │
│   │  │ NAT Gateway │                              │  │
│   │  └─────────────┘                              │  │
│   └───────────────────────────────────────────────┘  │
│                                                       │
│   S3 Buckets: assets, backups (encrypted+versioned)   │
│   DynamoDB: Terraform state locking                   │
└───────────────────────────────────────────────────────┘
```

## 📁 Project Structure

```
terraform-aws-infra/
├── bootstrap/              # Run ONCE — creates S3 + DynamoDB for remote state
│   ├── main.tf
│   └── variables.tf
├── modules/
│   ├── vpc/                # VPC, subnets, IGW, NAT, route tables
│   ├── ec2/                # EC2, SG, IAM role, user_data
│   ├── rds/                # RDS PostgreSQL, subnet group, SG, param group
│   └── s3/                 # S3 bucket, encryption, versioning, lifecycle
├── environments/
│   ├── dev/                # Dev environment (small instances, no multi-AZ)
│   └── prod/               # Prod environment (HA, multi-AZ, private subnets)
├── .github/workflows/
│   └── terraform.yml       # CI/CD: fmt, validate, plan, apply
└── README.md
```

## ⚖️ Dev vs Prod Differences

| Resource | Dev | Prod |
|----------|-----|------|
| EC2 type | t3.micro x1 | t3.small x2 |
| EC2 subnet | Public | Private |
| RDS type | db.t3.micro | db.t3.small |
| RDS Multi-AZ | ❌ | ✅ |
| RDS deletion protection | ❌ | ✅ |
| SSH allowed from | 0.0.0.0/0 | VPC only |
| S3 buckets | assets | assets + backups |
| VPC CIDR | 10.0.0.0/16 | 10.1.0.0/16 |

## 🚀 Getting Started

### Prerequisites
- Terraform >= 1.7
- AWS CLI configured (`aws configure`)
- AWS account with IAM permissions

### Step 1 — Bootstrap (run once)

Creates the S3 bucket and DynamoDB table for remote state.

```bash
cd bootstrap/
terraform init
terraform apply
```

### Step 2 — Deploy Dev

```bash
cd environments/dev/

# Create terraform.tfvars (never commit this!)
cat > terraform.tfvars <<EOF
db_password = "your-secure-password"
key_name    = "your-ec2-keypair"
EOF

terraform init
terraform plan
terraform apply
```

### Step 3 — Deploy Prod

```bash
cd environments/prod/
terraform init
terraform plan -var="db_password=YOUR_PASS" -var="key_name=YOUR_KEY"
terraform apply
```

### Destroy environment

```bash
terraform destroy -var="db_password=YOUR_PASS"
```

## 🔐 GitHub Secrets Required

| Secret | Description |
|--------|-------------|
| `AWS_ACCESS_KEY_ID` | AWS IAM access key |
| `AWS_SECRET_ACCESS_KEY` | AWS IAM secret key |
| `DEV_DB_PASSWORD` | RDS password for dev |
| `PROD_DB_PASSWORD` | RDS password for prod |

## ⚙️ GitHub Actions Pipeline

| Job | Trigger | What it does |
|-----|---------|--------------|
| `fmt` | PR + push | `terraform fmt -check -recursive` |
| `validate-dev` | PR + push | `terraform validate` for dev |
| `validate-prod` | PR + push | `terraform validate` for prod |
| `plan-dev` | PR only | `terraform plan` for dev |
| `apply-dev` | main push | `terraform apply` for dev |

## 📦 Modules

### vpc
Creates a full networking setup: VPC, public/private subnets across 2 AZs, Internet Gateway, NAT Gateway, and route tables.

### ec2
Launches EC2 instances with: security group (SSH/80/443), IAM role (SSM + CloudWatch), IMDSv2 enforced, encrypted EBS, and bootstrap user_data script.

### rds
PostgreSQL RDS with: private subnet group, security group (EC2-only ingress), custom parameter group, encryption at rest, automated backups, and deletion protection in prod.

### s3
S3 bucket with: all public access blocked, versioning enabled, AES256 encryption, and lifecycle rules to transition old versions to STANDARD_IA.

## 📜 License
MIT
