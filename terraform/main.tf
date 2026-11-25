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

resource "aws_subnet" "public_az" {
  count                   = length(var.azs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.azs[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "prod-public-${var.azs[count.index]}"
    Tier = "public"
  }
}

resource "aws_subnet" "private_app_az" {
  count             = length(var.azs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_app_subnet_cidrs[count.index]
  availability_zone = var.azs[count.index]

  tags = {
    Name = "prod-private-app-${var.azs[count.index]}"
    Tier = "app"
  }
}

resource "aws_subnet" "private_db_az" {
  count             = length(var.azs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_db_subnet_cidrs[count.index]
  availability_zone = var.azs[count.index]

  tags = {
    Name = "prod-private-db-${var.azs[count.index]}"
    Tier = "db"
  }
}

resource "aws_db_subnet_group" "private_db_group" {
  name       = "prod-mysql-private-subnets"
  subnet_ids = aws_subnet.private_db_az[*].id

  tags = {
    Name = "prod-mysql-private-subnets"
  }
}

resource "aws_sns_topic" "ops_alerts" {
  name = "prod-3tier-ops-alerts"

  tags = {
    Name = "prod-3tier-ops-alerts"
  }
}

resource "aws_sns_topic_subscription" "ops_email" {
  topic_arn = aws_sns_topic.ops_alerts.arn
  protocol  = "email"
  endpoint  = var.alarm_notification_email
}

resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  alarm_name          = "prod-web-alb-5xx-high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "HTTPCode_ELB_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Sum"
  threshold           = 5
  alarm_description   = "Triggers when ALB returns 5 or more 5XX responses in 5 minutes"
  alarm_actions       = [aws_sns_topic.ops_alerts.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = aws_lb.web.arn_suffix
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_cpu" {
  alarm_name          = "prod-mysql-db-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Triggers when RDS average CPU exceeds 80% over 10 minutes"
  alarm_actions       = [aws_sns_topic.ops_alerts.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.mysql.id
  }
}

resource "aws_cloudwatch_dashboard" "three_tier_ops" {
  dashboard_name = "prod-3tier-ops-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          region  = "us-east-1"
          title   = "ALB Requests & 5XX Errors"
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", aws_lb.web.arn_suffix],
            [".", "HTTPCode_ELB_5XX_Count", ".", "."]
          ]
          period = 300
          stat   = "Sum"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          region  = "us-east-1"
          title   = "RDS CPU Utilization (%)"
          metrics = [
            ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", aws_db_instance.mysql.id]
          ]
          period = 300
          stat   = "Average"
        }
      }
    ]
  })
}