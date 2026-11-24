variable "aws_region" {
  description = "AWS region for the 3-tier deployment"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for prod-3tier-vpc"
  type        = string
  default     = "10.0.0.0/16"
}

variable "private_db_subnet_ids" {
  description = "Subnet IDs across two AZs for the RDS DB subnet group"
  type        = list(string)
}

variable "app_sg_id" {
  description = "Security group ID for the application tier (app-sg)"
  type        = string
}

variable "db_instance_class" {
  description = "Free Tier-eligible RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_username" {
  description = "Master username for MySQL RDS"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Master password for MySQL RDS"
  type        = string
  sensitive   = true
}
