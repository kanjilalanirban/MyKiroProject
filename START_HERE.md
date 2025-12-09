# 🚀 START HERE - MyKiroProject Setup

Welcome! This guide will get you up and running in minutes.

## What You Have

A complete PCI-compliant EKS infrastructure with:
- ✅ Terraform code in `IaC/` folder
- ✅ GitHub Actions workflows for automated deployment
- ✅ Security scanning (tfsec, Checkov)
- ✅ Encryption, logging, and compliance features

## Quick Setup (3 Steps)

### Step 1: Push to GitHub

Run the quick start script:

```bash
./quick-start.sh
```

Choose option 1 (GitHub CLI) or 2 (Personal Access Token).

**Or manually:**

1. Create a Personal Access Token at: https://github.com/settings/tokens
   - Scopes needed: `repo`, `workflow`

2. Run these commands:
   ```bash
   git init
   git branch -M main
   git add .
   git commit -m "Initial commit: PCI-compliant EKS infrastructure"
   git remote add origin https://YOUR_USERNAME:YOUR_TOKEN@github.com/YOUR_USERNAME/MyKiroProject.git
   git push -u origin main
   ```

### Step 2: Configure AWS & GitHub

1. **Create AWS OIDC Provider** (detailed steps in `IaC/SETUP.md`):
   ```bash
   aws iam create-open-id-connect-provider \
     --url https://token.actions.githubusercontent.com \
     --client-id-list sts.amazonaws.com \
     --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
   ```

2. **Create IAM Role** for GitHub Actions (see `IaC/SETUP.md` for full policy)

3. **Add GitHub Secret**:
   - Go to: `https://github.com/YOUR_USERNAME/MyKiroProject/settings/secrets/actions`
   - Add secret: `AWS_ROLE_ARN` = `arn:aws:iam::ACCOUNT_ID:role/GitHubActionsEKSDeployRole`

### Step 3: Configure & Deploy

1. **Set up Terraform backend**:
   ```bash
   cd IaC
   cp backend.tf.example backend.tf
   # Edit backend.tf with your S3 bucket
   ```

2. **Configure variables**:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your VPC, subnets, etc.
   ```

3. **Deploy**:
   - Push to main branch → automatic deployment
   - Or use manual workflow in GitHub Actions

## File Structure

```
MyKiroProject/
├── IaC/                          # All Terraform code here
│   ├── main.tf                   # EKS cluster
│   ├── iam.tf                    # IAM roles
│   ├── security_groups.tf        # Network security
│   ├── node_groups.tf            # Worker nodes
│   ├── variables.tf              # Configuration
│   ├── README.md                 # Infrastructure docs
│   └── SETUP.md                  # Detailed AWS setup
├── .github/workflows/            # GitHub Actions
│   ├── terraform-deploy.yml      # Main deployment
│   ├── terraform-plan-on-pr.yml  # PR previews
│   └── security-scan.yml         # Security checks
├── quick-start.sh                # Run this first!
├── GITHUB_SETUP.md               # Detailed GitHub guide
└── README.md                     # Project overview
```

## Documentation

- **Quick Start**: You're reading it! 👋
- **GitHub Setup**: `GITHUB_SETUP.md` - Detailed GitHub instructions
- **AWS Setup**: `IaC/SETUP.md` - AWS OIDC, IAM, S3 backend
- **Infrastructure**: `IaC/README.md` - Terraform code documentation

## Workflows

### Automatic Deployment
- Push to `main` → runs `terraform apply`
- Pull Request → runs `terraform plan` and comments

### Manual Deployment
1. Go to: Actions → Deploy EKS Cluster
2. Click "Run workflow"
3. Choose: `plan`, `apply`, or `destroy`

## Common Commands

```bash
# Push to GitHub
./quick-start.sh

# View infrastructure docs
cd IaC && cat README.md

# View AWS setup guide
cd IaC && cat SETUP.md

# Test locally (after configuring backend)
cd IaC
terraform init
terraform plan
```

## Need Help?

1. **GitHub Setup Issues**: See `GITHUB_SETUP.md`
2. **AWS Configuration**: See `IaC/SETUP.md`
3. **Infrastructure Details**: See `IaC/README.md`
4. **Workflow Issues**: Check `.github/workflows/` files

## Security Checklist

Before deploying to production:

- [ ] AWS OIDC provider configured
- [ ] IAM role with least privilege permissions
- [ ] S3 backend with encryption enabled
- [ ] GitHub secrets configured (AWS_ROLE_ARN)
- [ ] terraform.tfvars not committed (in .gitignore)
- [ ] Branch protection enabled on main
- [ ] Security scans reviewed
- [ ] VPC and subnets configured correctly
- [ ] CIDR blocks restricted appropriately

## What's Next?

1. ✅ Run `./quick-start.sh` to push to GitHub
2. ✅ Follow `IaC/SETUP.md` for AWS configuration
3. ✅ Configure GitHub secret: AWS_ROLE_ARN
4. ✅ Update `IaC/terraform.tfvars` with your values
5. ✅ Push to main or run manual workflow
6. 🎉 Your EKS cluster will be deployed!

---

**Ready to start?**

```bash
./quick-start.sh
```

Good luck! 🚀
