output "vpc_id" {
  value = module.vpc.vpc_id
}

output "ec2_public_ips" {
  value = module.ec2.public_ips
}

output "rds_endpoint" {
  value     = module.rds.db_endpoint
  sensitive = true
}

output "s3_bucket" {
  value = module.s3_assets.bucket_id
}
