resource "aws_vpc" "prod_3tier_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "prod-3tier-vpc"
  }
}

resource "aws_db_subnet_group" "private_db" {
  name       = "prod-mysql-private-db-subnet-group"
  subnet_ids = var.private_db_subnet_ids

  tags = {
    Name = "prod-mysql-private-db-subnet-group"
  }
}

resource "aws_security_group" "rds_mysql_sg" {
  name        = "prod-mysql-rds-sg"
  description = "Allow MySQL port 3306 strictly from app-sg"
  vpc_id      = aws_vpc.prod_3tier_vpc.id

  ingress {
    description     = "MySQL access from application tier"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [var.app_sg_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "prod-mysql-rds-sg"
  }
}

resource "aws_db_instance" "prod_mysql_db" {
  identifier             = "prod-mysql-db"
  engine                 = "mysql"
  instance_class         = var.db_instance_class
  allocated_storage      = 20
  db_subnet_group_name   = aws_db_subnet_group.private_db.name
  vpc_security_group_ids = [aws_security_group.rds_mysql_sg.id]
  publicly_accessible    = false
  multi_az               = false
  ca_cert_identifier     = "rds-ca-rsa2048-g1"
  username               = var.db_username
  password               = var.db_password
  skip_final_snapshot    = true

  tags = {
    Name = "prod-mysql-db"
  }
}
