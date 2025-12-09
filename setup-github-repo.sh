#!/bin/bash

# Script to create GitHub repository and push code
set -e

echo "=========================================="
echo "GitHub Repository Setup for MyKiroProject"
echo "=========================================="
echo ""

# Check if gh CLI is installed
if ! command -v gh &> /dev/null; then
    echo "GitHub CLI (gh) is not installed."
    echo "Installing via Homebrew..."
    brew install gh
fi

echo "Step 1: Authenticate with GitHub"
echo "--------------------------------"
gh auth login

echo ""
echo "Step 2: Create Repository"
echo "-------------------------"
read -p "Do you want to create a new repository 'MyKiroProject'? (y/n): " CREATE_REPO

if [ "$CREATE_REPO" = "y" ] || [ "$CREATE_REPO" = "Y" ]; then
    echo "Creating repository..."
    gh repo create MyKiroProject --public --description "PCI-Compliant EKS Infrastructure as Code" || echo "Repository may already exist"
fi

echo ""
echo "Step 3: Initialize Git"
echo "----------------------"
git init
git branch -M main

echo ""
echo "Step 4: Add files to Git"
echo "------------------------"
git add .

echo ""
echo "Step 5: Commit files"
echo "--------------------"
git commit -m "Initial commit: PCI-compliant EKS infrastructure"

echo ""
echo "Step 6: Get GitHub username"
echo "---------------------------"
GITHUB_USERNAME=$(gh api user -q .login)
echo "GitHub username: $GITHUB_USERNAME"

echo ""
echo "Step 7: Add remote and push"
echo "----------------------------"
git remote add origin "https://github.com/${GITHUB_USERNAME}/MyKiroProject.git" 2>/dev/null || \
git remote set-url origin "https://github.com/${GITHUB_USERNAME}/MyKiroProject.git"

echo "Pushing to GitHub..."
git push -u origin main

echo ""
echo "=========================================="
echo "✅ Repository created and code pushed!"
echo "=========================================="
echo ""
echo "Repository URL: https://github.com/${GITHUB_USERNAME}/MyKiroProject"
echo ""
echo "Next Steps:"
echo "1. Set up AWS OIDC provider (see IaC/SETUP.md)"
echo "2. Configure GitHub secret: AWS_ROLE_ARN"
echo "3. Update IaC/backend.tf with your S3 bucket"
echo "4. Update IaC/terraform.tfvars with your configuration"
echo ""
echo "To configure GitHub Actions:"
echo "  cd IaC"
echo "  cat SETUP.md"
echo ""
