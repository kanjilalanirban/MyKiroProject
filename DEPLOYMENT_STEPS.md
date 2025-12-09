# 🚀 Complete Deployment Steps

Follow these steps exactly to deploy your PCI-compliant EKS cluster securely.

## Prerequisites Checklist

- [x] AWS CLI installed ✅
- [ ] AWS credentials configured
- [ ] IAM user created (NOT root!)
- [ ] Terraform installed
- [ ] kubectl installed

## Step 1: Create IAM User (DO NOT USE ROOT!)

### 1.1 Log into AWS Console
Go to: https://console.aws.amazon.com/

### 1.2 Create IAM User
1. Go to IAM → Users → Create user
2. User name: `github-actions-admin`
3. Check "Provide user access to the AWS Management Console" (optional)
4. Click "Next"

### 1.3 Attach Permissions
1. Select "Attach policies directly"
2. Search and select: `AdministratorAccess` (for setup only)
3. Click "Next" → "Create user"

### 1.4 Create Access Keys
1. Click on the user you just created
2. Go to "Security credentials" tab
3. Click "Create access key"
4. Select "Command Line Interface (CLI)"
5. Check the confirmation box
6. Click "Create access key"
6. **SAVE THESE CREDENTIALS** - you won't see them again!
   - Access Key ID
   - Secret Access Key

## Step 2: Configure AWS CLI

Run this command and enter your credentials:

```bash
aws configure
```

Enter:
- **AWS Access Key ID**: (paste from step 1.4)
- **AWS Secret Access Key**: (paste from step 1.4)
- **Default region name**: `us-east-1`
- **Default output format**: `json`

### Verify Configuration

```bash
aws sts get-caller-identity
```

You should see your account ID and user ARN (NOT root!).

## Step 3: Install Terraform

```bash
brew install terraform
```

Verify:
```bash
terraform version
```

## Step 4: Install kubectl

```bash
brew install kubectl
```

Verify:
```bash
kubectl version --client
```

## Step 5: Run OIDC Setup Script

Now run the secure setup script:

```bash
./scripts/setup-aws-oidc.sh
```

This will:
- ✅ Create OIDC provider
- ✅ Create IAM role for GitHub Actions
- ✅ Create S3 bucket for Terraform state
- ✅ Create DynamoDB table for state locking
- ✅ Output the role ARN

**SAVE THE ROLE ARN** - you'll need it for GitHub!

## Step 6: Add GitHub Secret

1. Go to: https://github.com/kanjilalanirban/MyKiroProject/settings/secrets/actions
2. Click "New repository secret"
3. Name: `AWS_ROLE_ARN`
4. Value: (paste the ARN from step 5)
5. Click "Add secret"

## Step 7: Get VPC and Subnet Information

### Option A: Use Default VPC (Quick Test)

```bash
# Get default VPC ID
export VPC_ID=$(aws ec2 describe-vpcs --filters "Name=isDefault,Values=true" --query "Vpcs[0].VpcId" --output text)
echo "VPC ID: $VPC_ID"

# Get subnet IDs
aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --query "Subnets[*].[SubnetId,AvailabilityZone]" --output table
```

### Option B: Create New VPC (Recommended for Production)

I can help you create a proper VPC with private subnets. Let me know if you want this!

## Step 8: Configure Backend

```bash
cd IaC
cp backend.tf.example backend.tf
```

Edit `backend.tf` and update the bucket name (from step 5 output):

```hcl
terraform {
  backend "s3" {
    bucket         = "terraform-state-XXXXX-eks"  # Replace with your bucket
    key            = "eks-pci-compliant/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}
```

## Step 9: Configure Variables

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`:

```hcl
cluster_name    = "my-pci-eks"
environment     = "production"
kubernetes_version = "1.28"

# Use values from Step 7
vpc_id     = "vpc-xxxxx"
subnet_ids = ["subnet-xxxxx", "subnet-yyyyy", "subnet-zzzzz"]

allowed_cidr_blocks  = ["10.0.0.0/8"]
enable_public_access = false

desired_size   = 2
min_size       = 1
max_size       = 3
instance_types = ["t3.small"]  # Start small for testing

associate_public_ip_address = false
log_retention_days          = 90
```

## Step 10: Test Locally (Optional but Recommended)

```bash
cd IaC

# Initialize
terraform init

# Validate
terraform validate

# Plan
terraform plan

# Review the plan carefully!
```

## Step 11: Commit and Push

```bash
# Add backend configuration (but NOT terraform.tfvars with real values!)
git add IaC/backend.tf
git commit -m "Configure Terraform backend"
git push origin main
```

**Note:** Don't commit `terraform.tfvars` with real values! It's in `.gitignore`.

## Step 12: Deploy via GitHub Actions

### Option A: Automatic Deployment

The push in Step 11 will trigger automatic deployment!

Monitor at: https://github.com/kanjilalanirban/MyKiroProject/actions

### Option B: Manual Deployment

1. Go to: https://github.com/kanjilalanirban/MyKiroProject/actions
2. Click "Deploy EKS Cluster"
3. Click "Run workflow"
4. Select "apply"
5. Click "Run workflow"

## Step 13: Monitor Deployment

1. Go to: https://github.com/kanjilalanirban/MyKiroProject/actions
2. Click on the running workflow
3. Watch the logs
4. Deployment takes ~15-20 minutes

## Step 14: Verify Deployment

After deployment completes:

```bash
# Configure kubectl
aws eks update-kubeconfig --name my-pci-eks --region us-east-1

# Check cluster
kubectl cluster-info
kubectl get nodes
kubectl get namespaces
```

## Step 15: Run Validation Tests

```bash
cd IaC/tests
./validate.sh my-pci-eks
```

This will verify:
- ✅ Cluster is active
- ✅ Encryption enabled
- ✅ Logging enabled
- ✅ Private endpoint configured
- ✅ Nodes are ready
- ✅ Security settings

## Troubleshooting

### "Access Denied" during OIDC setup
- Make sure you're using an IAM user with admin permissions
- NOT using root credentials

### "VPC not found"
- Double-check VPC ID from Step 7
- Make sure VPC exists in us-east-1 region

### "Subnet not found"
- Verify subnet IDs are correct
- Subnets must be in the same VPC
- Need at least 2 subnets in different AZs

### GitHub Actions failing
- Verify AWS_ROLE_ARN secret is set correctly
- Check workflow logs for specific errors
- Ensure IAM role has correct permissions

## Cost Estimate

For a small test cluster (t3.small, 2 nodes):
- EKS Control Plane: ~$73/month
- EC2 Nodes (2x t3.small): ~$30/month
- EBS Volumes: ~$10/month
- **Total: ~$113/month**

## Cleanup

To destroy everything:

```bash
cd IaC
terraform destroy
```

Or via GitHub Actions:
1. Go to Actions → Deploy EKS Cluster
2. Run workflow → Select "destroy"

## Next Steps After Deployment

1. ✅ Deploy sample application
2. ✅ Configure monitoring
3. ✅ Set up alerts
4. ✅ Run integration tests
5. ✅ Review security scan results

## Need Help?

If you get stuck at any step, let me know which step and what error you're seeing!

## Security Reminders

- ✅ Using IAM user (not root)
- ✅ Using OIDC (no credentials in GitHub)
- ✅ Encryption enabled
- ✅ Private endpoints
- ✅ Audit logging enabled
- ✅ Following PCI requirements

---

**Ready to start? Begin with Step 1!**
