output "db_endpoint" {
  description = "RDS instance endpoint"
  value       = aws_db_instance.main.endpoint
  sensitive   = true
}

output "db_name" {
  description = "Database name"
  value       = aws_db_instance.main.db_name
}

output "db_port" {
  description = "Database port"
  value       = aws_db_instance.main.port
}
