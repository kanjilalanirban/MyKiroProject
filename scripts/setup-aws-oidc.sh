#!/bin/bash

# Script to set up AWS OIDC provider and IAM role for GitHub Actions
# This is the SECURE way to authenticate GitHub Actions with AWS

set -e

echo "=========================================="
echo "AWS OIDC Setup for GitHub Actions"
echo "=========================================="
echo ""
echo "⚠️  IMPORTANT: Do NOT use root credentials!"
echo "This script will create a secure IAM role for GitHub Actions."
echo ""

# Get GitHub repository info
GITHUB_USERNAME="kanjilalanirban"
REPO_NAME="MyKiroProject"
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

echo "GitHub Repository: ${GITHUB_USERNAME}/${REPO_NAME}"
echo "AWS Account ID: ${AWS_ACCOUNT_ID}"
echo ""

# Step 1: Create OIDC Provider
echo "Step 1: Creating OIDC Provider..."
OIDC_EXISTS=$(aws iam list-open-id-connect-providers --query "OpenIDConnectProviderList[?contains(Arn, 'token.actions.githubusercontent.com')]" --output text)

if [ -z "$OIDC_EXISTS" ]; then
    aws iam create-open-id-connect-provider \
        --url https://token.actions.githubusercontent.com \
        --client-id-list sts.amazonaws.com \
        --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
    echo "✅ OIDC provider created"
else
    echo "✅ OIDC provider already exists"
fi

OIDC_PROVIDER_ARN="arn:aws:iam::${AWS_ACCOUNT_ID}:oidc-provider/token.actions.githubusercontent.com"

# Step 2: Create IAM Policy
echo ""
echo "Step 2: Creating IAM Policy..."

cat > /tmp/github-actions-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "eks:*",
        "ec2:Describe*",
        "ec2:CreateSecurityGroup",
        "ec2:DeleteSecurityGroup",
        "ec2:AuthorizeSecurityGroupIngress",
        "ec2:AuthorizeSecurityGroupEgress",
        "ec2:RevokeSecurityGroupIngress",
        "ec2:RevokeSecurityGroupEgress",
        "ec2:CreateTags",
        "ec2:DeleteTags",
        "ec2:CreateLaunchTemplate",
        "ec2:DeleteLaunchTemplate",
        "ec2:CreateLaunchTemplateVersion",
        "iam:CreateRole",
        "iam:DeleteRole",
        "iam:GetRole",
        "iam:PassRole",
        "iam:AttachRolePolicy",
        "iam:DetachRolePolicy",
        "iam:ListAttachedRolePolicies",
        "iam:CreatePolicy",
        "iam:DeletePolicy",
        "iam:GetPolicy",
        "iam:CreateOpenIDConnectProvider",
        "iam:GetOpenIDConnectProvider",
        "iam:DeleteOpenIDConnectProvider",
        "iam:TagOpenIDConnectProvider",
        "kms:CreateKey",
        "kms:DeleteKey",
        "kms:DescribeKey",
        "kms:GetKeyPolicy",
        "kms:PutKeyPolicy",
        "kms:CreateAlias",
        "kms:DeleteAlias",
        "kms:EnableKeyRotation",
        "kms:TagResource",
        "logs:CreateLogGroup",
        "logs:DeleteLogGroup",
        "logs:DescribeLogGroups",
        "logs:PutRetentionPolicy",
        "logs:TagLogGroup",
        "autoscaling:*"
      ],
      "Resource": "*"
    }
  ]
}
EOF

POLICY_ARN=$(aws iam list-policies --query "Policies[?PolicyName=='GitHubActionsEKSPolicy'].Arn" --output text)

if [ -z "$POLICY_ARN" ]; then
    POLICY_ARN=$(aws iam create-policy \
        --policy-name GitHubActionsEKSPolicy \
        --policy-document file:///tmp/github-actions-policy.json \
        --query 'Policy.Arn' \
        --output text)
    echo "✅ IAM policy created: ${POLICY_ARN}"
else
    echo "✅ IAM policy already exists: ${POLICY_ARN}"
fi

# Step 3: Create IAM Role
echo ""
echo "Step 3: Creating IAM Role..."

cat > /tmp/trust-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "${OIDC_PROVIDER_ARN}"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:${GITHUB_USERNAME}/${REPO_NAME}:*"
        }
      }
    }
  ]
}
EOF

ROLE_NAME="GitHubActionsEKSDeployRole"
ROLE_EXISTS=$(aws iam get-role --role-name ${ROLE_NAME} 2>/dev/null || echo "")

if [ -z "$ROLE_EXISTS" ]; then
    aws iam create-role \
        --role-name ${ROLE_NAME} \
        --assume-role-policy-document file:///tmp/trust-policy.json
    echo "✅ IAM role created: ${ROLE_NAME}"
else
    echo "✅ IAM role already exists: ${ROLE_NAME}"
fi

# Step 4: Attach Policy to Role
echo ""
echo "Step 4: Attaching policy to role..."
aws iam attach-role-policy \
    --role-name ${ROLE_NAME} \
    --policy-arn ${POLICY_ARN}
echo "✅ Policy attached to role"

ROLE_ARN="arn:aws:iam::${AWS_ACCOUNT_ID}:role/${ROLE_NAME}"

# Step 5: Create S3 Backend
echo ""
echo "Step 5: Creating S3 backend for Terraform state..."
BUCKET_NAME="terraform-state-${AWS_ACCOUNT_ID}-eks"

if aws s3 ls "s3://${BUCKET_NAME}" 2>/dev/null; then
    echo "✅ S3 bucket already exists: ${BUCKET_NAME}"
else
    aws s3api create-bucket \
        --bucket ${BUCKET_NAME} \
        --region us-east-1
    
    aws s3api put-bucket-versioning \
        --bucket ${BUCKET_NAME} \
        --versioning-configuration Status=Enabled
    
    aws s3api put-bucket-encryption \
        --bucket ${BUCKET_NAME} \
        --server-side-encryption-configuration '{
          "Rules": [{
            "ApplyServerSideEncryptionByDefault": {
              "SSEAlgorithm": "AES256"
            }
          }]
        }'
    
    aws s3api put-public-access-block \
        --bucket ${BUCKET_NAME} \
        --public-access-block-configuration \
          BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
    
    echo "✅ S3 bucket created: ${BUCKET_NAME}"
fi

# Step 6: Create DynamoDB Table
echo ""
echo "Step 6: Creating DynamoDB table for state locking..."
TABLE_NAME="terraform-state-lock"

if aws dynamodb describe-table --table-name ${TABLE_NAME} 2>/dev/null; then
    echo "✅ DynamoDB table already exists: ${TABLE_NAME}"
else
    aws dynamodb create-table \
        --table-name ${TABLE_NAME} \
        --attribute-definitions AttributeName=LockID,AttributeType=S \
        --key-schema AttributeName=LockID,KeyType=HASH \
        --billing-mode PAY_PER_REQUEST \
        --region us-east-1
    echo "✅ DynamoDB table created: ${TABLE_NAME}"
fi

# Cleanup temp files
rm -f /tmp/github-actions-policy.json /tmp/trust-policy.json

echo ""
echo "=========================================="
echo "✅ Setup Complete!"
echo "=========================================="
echo ""
echo "📋 Summary:"
echo "  OIDC Provider: ${OIDC_PROVIDER_ARN}"
echo "  IAM Role ARN: ${ROLE_ARN}"
echo "  S3 Bucket: ${BUCKET_NAME}"
echo "  DynamoDB Table: ${TABLE_NAME}"
echo ""
echo "🔐 Next Steps:"
echo ""
echo "1. Add GitHub Secret:"
echo "   Go to: https://github.com/${GITHUB_USERNAME}/${REPO_NAME}/settings/secrets/actions"
echo "   Name: AWS_ROLE_ARN"
echo "   Value: ${ROLE_ARN}"
echo ""
echo "2. Update backend.tf:"
echo "   cd IaC"
echo "   cp backend.tf.example backend.tf"
echo "   # Edit backend.tf and set:"
echo "   #   bucket = \"${BUCKET_NAME}\""
echo "   #   dynamodb_table = \"${TABLE_NAME}\""
echo ""
echo "3. Configure terraform.tfvars with your VPC and subnet IDs"
echo ""
echo "4. Push to GitHub to trigger deployment!"
echo ""
echo "⚠️  IMPORTANT: Never use root credentials!"
echo "    This IAM role provides secure, auditable access."
echo ""
