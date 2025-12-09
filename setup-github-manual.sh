#!/bin/bash

# Manual GitHub setup script using username/password or token
set -e

echo "=========================================="
echo "GitHub Repository Setup for MyKiroProject"
echo "=========================================="
echo ""

# Get GitHub credentials
read -p "Enter your GitHub username: " GITHUB_USERNAME
echo ""
echo "Note: GitHub no longer accepts passwords for Git operations."
echo "You need to use a Personal Access Token (PAT)."
echo ""
echo "To create a PAT:"
echo "1. Go to: https://github.com/settings/tokens"
echo "2. Click 'Generate new token (classic)'"
echo "3. Select scopes: repo (all), workflow"
echo "4. Copy the token"
echo ""
read -sp "Enter your Personal Access Token: " GITHUB_TOKEN
echo ""

# Initialize git
echo ""
echo "Initializing Git repository..."
git init
git branch -M main

# Configure git
echo ""
echo "Configuring Git..."
git config user.name "$GITHUB_USERNAME"
read -p "Enter your email for Git commits: " GIT_EMAIL
git config user.email "$GIT_EMAIL"

# Add files
echo ""
echo "Adding files to Git..."
git add .

# Commit
echo ""
echo "Committing files..."
git commit -m "Initial commit: PCI-compliant EKS infrastructure"

# Add remote with token
echo ""
echo "Adding GitHub remote..."
git remote add origin "https://${GITHUB_USERNAME}:${GITHUB_TOKEN}@github.com/${GITHUB_USERNAME}/MyKiroProject.git" 2>/dev/null || \
git remote set-url origin "https://${GITHUB_USERNAME}:${GITHUB_TOKEN}@github.com/${GITHUB_USERNAME}/MyKiroProject.git"

echo ""
echo "=========================================="
echo "Repository configured locally!"
echo "=========================================="
echo ""
echo "IMPORTANT: Before pushing, create the repository on GitHub:"
echo "1. Go to: https://github.com/new"
echo "2. Repository name: MyKiroProject"
echo "3. Description: PCI-Compliant EKS Infrastructure as Code"
echo "4. Choose Public or Private"
echo "5. Do NOT initialize with README, .gitignore, or license"
echo "6. Click 'Create repository'"
echo ""
read -p "Press Enter after creating the repository on GitHub..."

# Push to GitHub
echo ""
echo "Pushing to GitHub..."
git push -u origin main

echo ""
echo "=========================================="
echo "✅ Code successfully pushed to GitHub!"
echo "=========================================="
echo ""
echo "Repository URL: https://github.com/${GITHUB_USERNAME}/MyKiroProject"
echo ""
echo "Next Steps:"
echo "1. Review your repository: https://github.com/${GITHUB_USERNAME}/MyKiroProject"
echo "2. Set up AWS OIDC provider (see IaC/SETUP.md)"
echo "3. Configure GitHub secret: AWS_ROLE_ARN"
echo "   - Go to: https://github.com/${GITHUB_USERNAME}/MyKiroProject/settings/secrets/actions"
echo "   - Click 'New repository secret'"
echo "   - Name: AWS_ROLE_ARN"
echo "   - Value: Your IAM role ARN"
echo "4. Update IaC/backend.tf with your S3 bucket"
echo "5. Update IaC/terraform.tfvars with your configuration"
echo ""
echo "For detailed setup instructions:"
echo "  cd IaC"
echo "  cat SETUP.md"
echo ""
