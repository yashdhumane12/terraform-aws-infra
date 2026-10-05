output "vpc_id" {
  value = module.vpc.vpc_id
}

output "ec2_private_ips" {
  value = module.ec2.private_ips
}

output "rds_endpoint" {
  value     = module.rds.db_endpoint
  sensitive = true
}

output "s3_assets_bucket" {
  value = module.s3_assets.bucket_id
}

output "s3_backups_bucket" {
  value = module.s3_backups.bucket_id
}
