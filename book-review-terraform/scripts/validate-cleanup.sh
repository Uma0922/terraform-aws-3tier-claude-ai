#!/bin/bash

REGION="ap-south-1"

echo "🔍 Checking AWS resource cleanup in $REGION..."

echo "----------------------------------------"
echo "EC2 Instances:"
EC2=$(aws ec2 describe-instances --region $REGION \
--query 'Reservations[].Instances[].InstanceId' --output text)

if [ -z "$EC2" ]; then
  echo "✅ No EC2 instances found"
else
  echo "❌ EC2 still exists: $EC2"
fi

echo "----------------------------------------"
echo "Load Balancers:"
ALB=$(aws elbv2 describe-load-balancers --region $REGION \
--query 'LoadBalancers[].LoadBalancerName' --output text)

if [ -z "$ALB" ]; then
  echo "✅ No Load Balancers found"
else
  echo "❌ ALB still exists: $ALB"
fi

echo "----------------------------------------"
echo "RDS Instances:"
RDS=$(aws rds describe-db-instances --region $REGION \
--query 'DBInstances[].DBInstanceIdentifier' --output text)

if [ -z "$RDS" ]; then
  echo "✅ No RDS instances found"
else
  echo "❌ RDS still exists: $RDS"
fi

echo "----------------------------------------"
echo "VPCs:"
VPC=$(aws ec2 describe-vpcs --region $REGION \
--query 'Vpcs[?IsDefault==`false`].VpcId' --output text)

if [ -z "$VPC" ]; then
  echo "✅ No custom VPC found"
else
  echo "❌ Custom VPC still exists: $VPC"
fi

echo "----------------------------------------"
echo "🎯 Cleanup validation completed!"