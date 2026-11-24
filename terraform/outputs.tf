output "vpc_id" {
  description = "ID of prod-3tier-vpc"
  value       = aws_vpc.prod_3tier_vpc.id
}

output "rds_endpoint" {
  description = "Endpoint address of prod-mysql-db"
  value       = aws_db_instance.prod_mysql_db.address
}

output "rds_port" {
  description = "Port of prod-mysql-db"
  value       = aws_db_instance.prod_mysql_db.port
}
