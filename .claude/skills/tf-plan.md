# Terraform Plan Skill

## Goal
Preview infrastructure

## Steps
1. Run:
   terraform validate
   terraform plan

## Expected
- No validation errors
- Resources listed:
  - VPC
  - Subnets
  - EC2
  - ALB
  - RDS

## If Error
- Fix syntax
- Check variables
- Check missing inputs

## Ask User
"Share terraform plan output"