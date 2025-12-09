# 🔒 Secure Deployment Guide

## ⚠️ CRITICAL: Do NOT Use Root Credentials!

Using AWS root credentials violates:
- ✗ PCI DSS Requirements 7.1, 8.2
- ✗ AWS Security Best Practices
- ✗ Principle of Least Privilege
- ✗ Audit and Compliance Standards

**Root credentials should NEVER be used for:**
- Automated deployments
- GitHub Actions
- Terraform
- Any programmatic access

## ✅ Secure Method: IAM Role with OIDC

This method:
- ✓ No credentials stored in GitHub
- ✓ Temporary credentials only
- ✓ Full audit trail
- ✓ PCI compliant
- ✓ Can be revoked instantly
- ✓ Follows AWS best practices

## Quick Setup (5 Minutes)

### Step 1: Run the Setup Script

```bash
# Make sure you're using an IAM user (not root!) with admin permissions
./scripts/setup-aws-oidc.sh
```

This will automatically:
1. Create OIDC provider
2. Create IAM role with least privilege
3. Create S3 bucket for Terraform state
4. Create DynamoDB table for state locking
5. Output the role ARN

### Step 2: Add GitHub Secret

The script will output a role ARN like:
```
arn:aws:iam::123456789012:role/GitHubActionsEKSDeployRole
```

Add it to GitHub:
1. Go to: https://github.com/kanjilalanirban/MyKiroProject/settings/secrets/actions
2. Click "New repository secret"
3. Name: `AWS_ROLE_ARN`
4. Value: (paste the ARN from script output)
5. Click "Add secret"

### Step 3: Configure Backend

```bash
cd IaC
cp backend.tf.example backend.tf
```

Edit `backend.tf` with the bucket name from script output:
```hcl
terraform {
  backend "s3" {
    bucket         = "terraform-state-ACCOUNT_ID-eks"  # From script output
    key            = "eks-pci-compliant/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}
```

### Step 4: Configure Variables

You need a VPC and subnets. If you don't have them:

**Option A: Use Default VPC (for testing only)**
```bash
# Get default VPC
aws ec2 describe-vpcs --filters "Name=isDefault,Values=true" --query "Vpcs[0].VpcId" --output text

# Get subnets
aws ec2 describe-subnets --filters "Name=vpc-id,Values=YOUR_VPC_ID" --query "Subnets[*].SubnetId" --output json
```

**Option B: Create a VPC (recommended)**
```bash
# I can help you create a VPC if needed
```

Edit `IaC/terraform.tfvars`:
```hcl
cluster_name    = "my-pci-eks"
environment     = "production"
kubernetes_version = "1.28"

vpc_id     = "vpc-xxxxx"  # Your VPC ID
subnet_ids = ["subnet-xxxxx", "subnet-yyyyy", "subnet-zzzzz"]  # Your subnet IDs

allowed_cidr_blocks  = ["10.0.0.0/8"]  # Your internal network
enable_public_access = false

desired_size   = 3
min_size       = 2
max_size       = 5
instance_types = ["t3.medium"]

associate_public_ip_address = false
log_retention_days          = 90
```

### Step 5: Commit and Push

```bash
git add IaC/backend.tf IaC/terraform.tfvars
git commit -m "Configure backend and variables"
git push origin main
```

This will trigger the deployment automatically!

### Step 6: Monitor Deployment

Watch the deployment:
1. Go to: https://github.com/kanjilalanirban/MyKiroProject/actions
2. Click on the running workflow
3. Monitor the progress

## Alternative: Manual Deployment

If you prefer to test locally first:

```bash
cd IaC

# Initialize
terraform init

# Plan
terraform plan

# Apply (if plan looks good)
terraform apply
```

## What Happens During Deployment

1. **GitHub Actions starts**
   - Authenticates with AWS using OIDC (no credentials!)
   - Assumes the IAM role temporarily

2. **Terraform runs**
   - Creates KMS keys for encryption
   - Creates EKS cluster with encryption enabled
   - Creates node groups with encrypted volumes
   - Configures security groups
   - Sets up CloudWatch logging
   - Creates OIDC provider for IRSA

3. **Validation**
   - Tests run automatically
   - Security scans execute
   - Results posted to workflow

## Security Benefits of This Approach

### vs Root Credentials:
| Feature | Root Credentials | IAM Role with OIDC |
|---------|-----------------|-------------------|
| Credentials stored | ❌ Yes (dangerous) | ✅ No |
| Credential rotation | ❌ Manual | ✅ Automatic |
| Audit trail | ⚠️ Limited | ✅ Complete |
| Can be revoked | ❌ No | ✅ Yes, instantly |
| Least privilege | ❌ No | ✅ Yes |
| MFA support | ❌ No | ✅ Yes |
| PCI compliant | ❌ No | ✅ Yes |
| Temporary credentials | ❌ No | ✅ Yes (1 hour) |

## Troubleshooting

### "Access Denied" Errors

Check:
1. IAM role ARN is correct in GitHub secret
2. Trust policy includes your repository
3. IAM policy has required permissions

### "Backend Initialization Failed"

Check:
1. S3 bucket name is correct
2. DynamoDB table exists
3. IAM role has S3 and DynamoDB permissions

### "VPC Not Found"

You need to provide a valid VPC ID. Options:
1. Use existing VPC
2. Create new VPC
3. Use default VPC (testing only)

## Creating a VPC (If Needed)

If you don't have a VPC, I can help you create one:

```bash
# Let me know if you need this!
```

## Best Practices

1. **Never use root credentials** - Use IAM users/roles
2. **Enable MFA** - On all IAM users
3. **Rotate credentials** - Regularly (OIDC does this automatically)
4. **Monitor access** - Use CloudTrail
5. **Least privilege** - Only grant needed permissions
6. **Audit regularly** - Review IAM policies

## Next Steps

1. ✅ Run `./scripts/setup-aws-oidc.sh`
2. ✅ Add GitHub secret (AWS_ROLE_ARN)
3. ✅ Configure backend.tf
4. ✅ Configure terraform.tfvars
5. ✅ Push to GitHub
6. ✅ Monitor deployment

## Need Help?

If you need help with:
- Creating a VPC
- Getting subnet IDs
- Configuring variables
- Troubleshooting errors

Just let me know!

## Summary

**DO THIS:** ✅
```bash
./scripts/setup-aws-oidc.sh  # Secure method
```

**NOT THIS:** ❌
```bash
# Never store root credentials anywhere!
```

The secure method takes the same amount of time but provides:
- Better security
- Full audit trail
- PCI compliance
- Peace of mind

Let's do it the right way! 🔒
