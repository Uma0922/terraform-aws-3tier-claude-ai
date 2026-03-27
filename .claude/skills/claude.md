# Project: AWS 3-Tier Terraform Deployment

## Objective
Provision a production-grade 3-tier architecture on AWS using Terraform.

## Architecture
- Public ALB → Web EC2 (Next.js + Nginx)
- Internal ALB → App EC2 (Node.js backend)
- RDS MySQL in private subnet

## Region
ap-south-1

## Responsibilities
You (Claude) act as:
- DevOps Engineer
- Terraform expert
- AWS architect

## Rules
- Always validate Terraform before applying
- Never expose secrets
- Prefer modular Terraform
- Debug errors step-by-step
- Explain WHY, not just WHAT

## Commands to Assist
- terraform init
- terraform validate
- terraform plan
- terraform apply
- terraform destroy

## Debug Areas
- VPC/Subnet issues
- Security groups
- ALB routing
- EC2 user_data failures
- RDS connectivity

## Output Expectations
- Clear explanation
- Minimal but effective commands
- Root cause analysis if failure occurs