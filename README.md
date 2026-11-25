# AWS 3-Tier Web Architecture (Multi-AZ Topology & Free Tier Guardrails)

## Overview
This project documents and codifies a three-tier AWS web architecture (`prod-3tier-vpc`, `10.0.0.0/16`) in `us-east-1` aligned with the **AWS Well-Architected Framework** and the visual topology in `docs/WebApp-Production-VPC.jpeg`.

## Architecture & Tier Breakdown
- **Networking & Multi-AZ Layout:** `prod-3tier-vpc` (`10.0.0.0/16`) in `us-east-1` spanning **Availability Zone A** and **Availability Zone B**, segmented into public subnets, private application subnets, and private database subnets behind network ACLs (NACLs) with an Internet Gateway at the VPC boundary.
- **Ingress, Edge & Compute:** Traffic flows through `prod-web-alb` and target group `prod-web-tg` to compute instances managed by `prod-web-asg` (`app-sg`), with target reference edge and security services (`Amazon Route 53`, `Amazon CloudFront`, `AWS WAF`) and operational shell access (`AWS Systems Manager`) shown in `docs/WebApp-Production-VPC.jpeg`.
- **Database Tier:** MySQL Community RDS (`prod-mysql-db`) placed in private subnets with `Public access: No`, inbound TCP `3306` restricted to `app-sg`, and TLS certificate `rds-ca-rsa2048-g1`. Multi-AZ failover is controlled via `enable_rds_multi_az` (defaulted to `false` to protect Free Tier credits).
- **Monitoring & Notifications:** Amazon CloudWatch dashboard (`prod-3tier-ops-dashboard`) and alarms (`prod-web-alb-5xx-high`, `prod-mysql-db-cpu-high`) wired to an Amazon SNS topic (`prod-3tier-ops-alerts`) for alert notifications.

## Repository Structure
- `README.md` — Architecture documentation, Well-Architected alignment, Free Tier notes, and cleanup plan.
- `docs/WebApp-Production-VPC.jpeg` — Architecture topology diagram.
- `.gitignore` — Excludes Terraform state files (`.tfstate*`), `.terraform/`, local caches, and sensitive credentials.
- `terraform/main.tf` — Core VPC, subnet, ALB/ASG/RDS, CloudWatch, and SNS resource definitions.
- `terraform/variables.tf` — Input variables including Multi-AZ CIDRs, `enable_rds_multi_az`, and `alarm_notification_email`.
- `terraform/outputs.tf` — Key outputs including SNS topic ARN and CloudWatch dashboard name.
- `terraform/versions.tf` — Terraform and provider version constraints.

## AWS Well-Architected Alignment (6 Pillars)
- **Operational Excellence:** Infrastructure is codified in Terraform, paired with CloudWatch alarms/dashboard, SNS alerting, and `.gitignore` hygiene.
- **Security:** Database tier isolated in private subnets (`Public access: No`), port `3306` restricted to `app-sg`, TLS (`rds-ca-rsa2048-g1`), edge/WAF reference design, and Systems Manager access.
- **Reliability:** Multi-AZ subnet and compute distribution across two Availability Zones plus snapshot recovery, keeping single-AZ RDS configurable for cost control.
- **Performance Efficiency:** Load distribution across AZs with CloudFront static caching and ALB/ASG health routing.
- **Cost Optimization:** Free Tier-safe defaults (`enable_rds_multi_az = false`), lean monitoring, and mandatory post-review teardown to prevent ongoing charges.
- **Sustainability:** Right-sized test footprint and scheduled cleanup after evaluation.

## Free Tier Scope Note & Post-Evaluation Cleanup
- Certain edge, WAF, and full Multi-AZ database options shown in `docs/WebApp-Production-VPC.jpeg` are kept lean or configurable due to AWS Free Tier limits, account/service restrictions, and cost guardrails.
- Once grading/voucher review finishes, remove billable or lingering resources (`prod-web-asg`, `prod-web-alb`/`prod-web-tg`, any NAT Gateways or unused Elastic IPs, `prod-mysql-db` and unneeded snapshots, CloudWatch/SNS resources, and remaining VPC components).