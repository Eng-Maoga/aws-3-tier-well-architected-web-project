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

variable "azs" {
  description = "Availability Zones for Multi-AZ subnets"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDRs across AZ A and AZ B"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_app_subnet_cidrs" {
  description = "Private application subnet CIDRs across AZ A and AZ B"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "private_db_subnet_cidrs" {
  description = "Private database subnet CIDRs across AZ A and AZ B"
  type        = list(string)
  default     = ["10.0.21.0/24", "10.0.22.0/24"]
}

variable "enable_rds_multi_az" {
  description = "Enable RDS Multi-AZ failover; keep false by default for Free Tier safety"
  type        = bool
  default     = false
}

variable "alarm_notification_email" {
  description = "Email endpoint subscribed to CloudWatch SNS alerts"
  type        = string
}