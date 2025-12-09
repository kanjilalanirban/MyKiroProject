# GitHub Setup Guide

This guide will help you push your code to GitHub and set up the automated deployment pipeline.

## Prerequisites

- GitHub account
- Git installed on your machine

## Option 1: Using GitHub CLI (Recommended)

### Step 1: Install GitHub CLI

```bash
brew install gh
```

### Step 2: Run the setup script

```bash
./setup-github-repo.sh
```

This will:
- Authenticate with GitHub
- Create the repository
- Initialize git
- Commit and push your code

## Option 2: Manual Setup with Personal Access Token

### Step 1: Create a Personal Access Token

1. Go to: https://github.com/settings/tokens
2. Click "Generate new token (classic)"
3. Give it a name: "MyKiroProject"
4. Select scopes:
   - ✅ repo (all)
   - ✅ workflow
5. Click "Generate token"
6. **Copy the token** (you won't see it again!)

### Step 2: Run the manual setup script

```bash
./setup-github-manual.sh
```

Follow the prompts to enter your username and token.

## Option 3: Completely Manual Setup

### Step 1: Create Repository on GitHub

1. Go to: https://github.com/new
2. Repository name: `MyKiroProject`
3. Description: `PCI-Compliant EKS Infrastructure as Code`
4. Choose Public or Private
5. **Do NOT** initialize with README, .gitignore, or license
6. Click "Create repository"

### Step 2: Initialize Git locally

```bash
# Initialize git
git init
git branch -M main

# Configure git (if not already configured)
git config user.name "YOUR_USERNAME"
git config user.email "your.email@example.com"

# Add all files
git add .

# Commit
git commit -m "Initial commit: PCI-compliant EKS infrastructure"
```

### Step 3: Push to GitHub

Replace `YOUR_USERNAME` and `YOUR_TOKEN` with your actual values:

```bash
# Add remote
git remote add origin https://YOUR_USERNAME:YOUR_TOKEN@github.com/YOUR_USERNAME/MyKiroProject.git

# Push
git push -u origin main
```

Or use SSH (if you have SSH keys set up):

```bash
# Add remote
git remote add origin git@github.com:YOUR_USERNAME/MyKiroProject.git

# Push
git push -u origin main
```

## After Pushing to GitHub

### Step 1: Verify Repository

Visit: `https://github.com/YOUR_USERNAME/MyKiroProject`

You should see all your files including:
- IaC/ folder with Terraform code
- .github/workflows/ with GitHub Actions
- README.md

### Step 2: Set Up AWS OIDC Provider

Follow the detailed instructions in `IaC/SETUP.md`:

```bash
cd IaC
cat SETUP.md
```

Key steps:
1. Create OIDC provider in AWS
2. Create IAM role for GitHub Actions
3. Attach required policies
4. Create S3 bucket for Terraform state
5. Create DynamoDB table for state locking

### Step 3: Configure GitHub Secrets

1. Go to: `https://github.com/YOUR_USERNAME/MyKiroProject/settings/secrets/actions`
2. Click "New repository secret"
3. Add secret:
   - Name: `AWS_ROLE_ARN`
   - Value: `arn:aws:iam::YOUR_ACCOUNT_ID:role/GitHubActionsEKSDeployRole`

### Step 4: Configure Terraform Backend

```bash
cd IaC
cp backend.tf.example backend.tf
# Edit backend.tf with your S3 bucket details
```

### Step 5: Configure Variables

You have two options:

**Option A: Use GitHub Secrets (Recommended for sensitive data)**

Add these secrets in GitHub:
- `CLUSTER_NAME`
- `ENVIRONMENT`
- `VPC_ID`
- `SUBNET_IDS`
- `ALLOWED_CIDR_BLOCKS`

Then modify `.github/workflows/terraform-deploy.yml` to create terraform.tfvars from secrets.

**Option B: Commit terraform.tfvars (Not recommended for production)**

```bash
cd IaC
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
# Remove terraform.tfvars from .gitignore if you want to commit it
```

### Step 6: Test the Pipeline

#### Test Plan on Pull Request

1. Create a new branch:
   ```bash
   git checkout -b test-deployment
   ```

2. Make a small change to any .tf file

3. Commit and push:
   ```bash
   git add .
   git commit -m "Test deployment"
   git push origin test-deployment
   ```

4. Create a Pull Request on GitHub

5. GitHub Actions will automatically run `terraform plan` and comment on the PR

#### Test Deployment

1. Merge the PR to main branch

2. GitHub Actions will automatically run `terraform apply`

3. Monitor the deployment:
   - Go to: `https://github.com/YOUR_USERNAME/MyKiroProject/actions`
   - Click on the running workflow
   - Watch the logs

#### Manual Deployment

1. Go to: `https://github.com/YOUR_USERNAME/MyKiroProject/actions`

2. Click "Deploy EKS Cluster"

3. Click "Run workflow"

4. Choose action:
   - `plan`: Preview changes
   - `apply`: Deploy infrastructure
   - `destroy`: Tear down infrastructure

5. Click "Run workflow"

## Troubleshooting

### Authentication Failed

If you get authentication errors:
- Verify your Personal Access Token is correct
- Ensure the token has `repo` and `workflow` scopes
- Token may have expired - create a new one

### Repository Already Exists

If the repository already exists:
```bash
git remote set-url origin https://YOUR_USERNAME:YOUR_TOKEN@github.com/YOUR_USERNAME/MyKiroProject.git
git push -u origin main
```

### GitHub Actions Not Running

- Check that workflows are enabled in repository settings
- Verify AWS_ROLE_ARN secret is set correctly
- Check workflow logs for errors

### Terraform State Lock

If state is locked:
```bash
aws dynamodb scan --table-name terraform-state-lock
# If needed, delete the lock (use with caution)
```

## Security Best Practices

1. **Never commit sensitive data**:
   - terraform.tfvars with real values
   - AWS credentials
   - Private keys

2. **Use GitHub Secrets** for sensitive configuration

3. **Enable branch protection** on main branch:
   - Require pull request reviews
   - Require status checks to pass

4. **Review security scan results** regularly

5. **Rotate tokens** periodically

## Next Steps

1. ✅ Push code to GitHub
2. ✅ Set up AWS OIDC provider
3. ✅ Configure GitHub secrets
4. ✅ Test the pipeline
5. 📖 Review `IaC/README.md` for infrastructure details
6. 🚀 Deploy your EKS cluster!

## Support

For detailed AWS and Terraform configuration, see:
- `IaC/SETUP.md` - Detailed setup instructions
- `IaC/README.md` - Infrastructure documentation

For GitHub Actions issues:
- Check workflow logs in the Actions tab
- Review `.github/workflows/` files
