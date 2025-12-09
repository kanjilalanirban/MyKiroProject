# GitHub Actions Setup Guide

This guide will help you set up GitHub Actions to automatically deploy your PCI-compliant EKS cluster.

## Prerequisites

1. AWS Account with appropriate permissions
2. GitHub repository
3. S3 bucket for Terraform state (recommended)
4. DynamoDB table for state locking (recommended)

## Step 1: Configure AWS OIDC Provider for GitHub Actions

This allows GitHub Actions to authenticate with AWS without storing long-lived credentials.

### Create OIDC Provider in AWS

```bash
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
```

### Create IAM Role for GitHub Actions

Create a file `github-actions-role.json`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::YOUR_ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:YOUR_GITHUB_USERNAME/YOUR_REPO_NAME:*"
        }
      }
    }
  ]
}
```

Create the role:

```bash
aws iam create-role \
  --role-name GitHubActionsEKSDeployRole \
  --assume-role-policy-document file://github-actions-role.json
```

### Attach Required Policies

```bash
# Create a custom policy with required permissions
cat > eks-deploy-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "eks:*",
        "ec2:*",
        "iam:*",
        "kms:*",
        "logs:*",
        "autoscaling:*",
        "elasticloadbalancing:*"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject"
      ],
      "Resource": "arn:aws:s3:::your-terraform-state-bucket/*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket"
      ],
      "Resource": "arn:aws:s3:::your-terraform-state-bucket"
    },
    {
      "Effect": "Allow",
      "Action": [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:DeleteItem"
      ],
      "Resource": "arn:aws:dynamodb:*:*:table/terraform-state-lock"
    }
  ]
}
EOF

aws iam create-policy \
  --policy-name EKSDeployPolicy \
  --policy-document file://eks-deploy-policy.json

aws iam attach-role-policy \
  --role-name GitHubActionsEKSDeployRole \
  --policy-arn arn:aws:iam::YOUR_ACCOUNT_ID:policy/EKSDeployPolicy
```

## Step 2: Create S3 Backend for Terraform State

```bash
# Create S3 bucket
aws s3api create-bucket \
  --bucket your-terraform-state-bucket \
  --region us-east-1

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket your-terraform-state-bucket \
  --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption \
  --bucket your-terraform-state-bucket \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'

# Block public access
aws s3api put-public-access-block \
  --bucket your-terraform-state-bucket \
  --public-access-block-configuration \
    BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

# Create DynamoDB table for state locking
aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1
```

## Step 3: Configure GitHub Repository Secrets

Go to your GitHub repository → Settings → Secrets and variables → Actions

Add the following secret:

- `AWS_ROLE_ARN`: The ARN of the IAM role created above
  - Example: `arn:aws:iam::123456789012:role/GitHubActionsEKSDeployRole`

## Step 4: Configure Backend

Copy the backend configuration:

```bash
cp backend.tf.example backend.tf
```

Edit `backend.tf` with your S3 bucket and DynamoDB table details.

## Step 5: Configure Variables

Copy the example tfvars:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your configuration. **DO NOT commit this file** (it's in .gitignore).

Instead, you can:

### Option A: Use GitHub Secrets for Variables

Add these as GitHub secrets and modify the workflow to create terraform.tfvars:

```yaml
- name: Create terraform.tfvars
  run: |
    cat > terraform.tfvars <<EOF
    cluster_name = "${{ secrets.CLUSTER_NAME }}"
    environment = "${{ secrets.ENVIRONMENT }}"
    vpc_id = "${{ secrets.VPC_ID }}"
    subnet_ids = ${{ secrets.SUBNET_IDS }}
    allowed_cidr_blocks = ${{ secrets.ALLOWED_CIDR_BLOCKS }}
    EOF
```

### Option B: Use Terraform Cloud/Enterprise

Configure Terraform Cloud workspace and store variables there.

## Step 6: Push to GitHub

```bash
# Add all files
git add .

# Commit
git commit -m "Initial commit: PCI-compliant EKS Terraform module"

# Add remote (replace with your repository URL)
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO.git

# Push to main branch
git branch -M main
git push -u origin main
```

## Step 7: Workflow Usage

### Automatic Deployment

- **Push to main**: Automatically runs `terraform apply`
- **Pull Request**: Runs `terraform plan` and comments on PR

### Manual Deployment

Go to Actions → Deploy EKS Cluster → Run workflow

Choose action:
- `plan`: Preview changes
- `apply`: Deploy infrastructure
- `destroy`: Tear down infrastructure

## Security Considerations

1. **Least Privilege**: Review and restrict IAM permissions to minimum required
2. **Branch Protection**: Enable branch protection rules on main branch
3. **Required Reviews**: Require PR reviews before merging
4. **State Encryption**: Ensure S3 bucket and DynamoDB table are encrypted
5. **Audit Logging**: Enable CloudTrail for all API calls
6. **Secret Rotation**: Regularly rotate any credentials
7. **Environment Separation**: Use separate AWS accounts for dev/staging/prod

## Monitoring Deployments

1. Check GitHub Actions tab for workflow runs
2. Review Terraform plan output in PR comments
3. Monitor AWS CloudWatch for cluster logs
4. Set up alerts for deployment failures

## Troubleshooting

### Authentication Errors

- Verify OIDC provider is configured correctly
- Check IAM role trust policy matches your repository
- Ensure AWS_ROLE_ARN secret is set correctly

### Terraform State Lock

If state is locked:

```bash
# List locks
aws dynamodb scan --table-name terraform-state-lock

# Remove lock (use with caution)
aws dynamodb delete-item \
  --table-name terraform-state-lock \
  --key '{"LockID":{"S":"your-lock-id"}}'
```

### Plan/Apply Failures

- Check workflow logs in GitHub Actions
- Verify all required variables are set
- Ensure AWS permissions are sufficient
- Check VPC and subnet configurations

## Cleanup

To destroy the infrastructure:

1. Go to Actions → Deploy EKS Cluster → Run workflow
2. Select `destroy` action
3. Confirm and run

Or manually:

```bash
terraform destroy
```

## Additional Resources

- [GitHub Actions OIDC with AWS](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services)
- [Terraform S3 Backend](https://www.terraform.io/docs/language/settings/backends/s3.html)
- [EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)
- [PCI DSS Requirements](https://www.pcisecuritystandards.org/)
