# Quick Command Reference

## Push to GitHub (Choose One Method)

### Method 1: Using Quick Start Script (Easiest)
```bash
./quick-start.sh
```

### Method 2: Using GitHub CLI
```bash
# Install GitHub CLI
brew install gh

# Run setup
./setup-github-repo.sh
```

### Method 3: Manual with Token
```bash
# Get token from: https://github.com/settings/tokens
# Then run:
./setup-github-manual.sh
```

### Method 4: Completely Manual
```bash
# 1. Create token at: https://github.com/settings/tokens
# 2. Create repo at: https://github.com/new (name: MyKiroProject)
# 3. Run these commands:

git init
git branch -M main
git add .
git commit -m "Initial commit: PCI-compliant EKS infrastructure"
git remote add origin https://YOUR_USERNAME:YOUR_TOKEN@github.com/YOUR_USERNAME/MyKiroProject.git
git push -u origin main
```

## After Pushing - AWS Setup

### Create OIDC Provider
```bash
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
```

### Create S3 Backend
```bash
# Create bucket
aws s3api create-bucket --bucket YOUR-terraform-state-bucket --region us-east-1

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket YOUR-terraform-state-bucket \
  --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption \
  --bucket YOUR-terraform-state-bucket \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'

# Create DynamoDB table
aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1
```

### Configure Terraform
```bash
cd IaC
cp backend.tf.example backend.tf
cp terraform.tfvars.example terraform.tfvars

# Edit these files with your values
# backend.tf - add your S3 bucket name
# terraform.tfvars - add your VPC, subnets, etc.
```

## GitHub Configuration

### Add Secret
```bash
# Go to: https://github.com/YOUR_USERNAME/MyKiroProject/settings/secrets/actions
# Click: New repository secret
# Name: AWS_ROLE_ARN
# Value: arn:aws:iam::YOUR_ACCOUNT_ID:role/GitHubActionsEKSDeployRole
```

## Deploy

### Automatic (Push to Main)
```bash
git add .
git commit -m "Configure deployment"
git push origin main
```

### Manual (GitHub Actions)
```bash
# Go to: https://github.com/YOUR_USERNAME/MyKiroProject/actions
# Click: Deploy EKS Cluster → Run workflow
# Choose: apply
```

## Local Testing
```bash
cd IaC
terraform init
terraform plan
terraform apply  # Only if you want to deploy locally
```

## Useful Links

- Create Token: https://github.com/settings/tokens
- Create Repo: https://github.com/new
- Your Actions: https://github.com/YOUR_USERNAME/MyKiroProject/actions
- Your Secrets: https://github.com/YOUR_USERNAME/MyKiroProject/settings/secrets/actions

## Get Help

```bash
# View documentation
cat START_HERE.md          # Quick start guide
cat GITHUB_SETUP.md        # Detailed GitHub setup
cat IaC/SETUP.md           # Detailed AWS setup
cat IaC/README.md          # Infrastructure documentation
```
