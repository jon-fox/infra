output "rds_endpoint" {
  value = aws_db_instance.rds_postgres.endpoint
}

output "master_password_secret_arn" {
  value = aws_secretsmanager_secret.rds_master_secret.arn
}