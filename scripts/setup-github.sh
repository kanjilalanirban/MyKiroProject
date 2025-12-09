#!/bin/bash

# Script to help set up GitHub repository
set -e

echo "=== GitHub Repository Setup ==="
echo ""

# Check if git is initialized
if [ ! -d .git ]; then
    echo "Initializing git repository..."
    git init
    git branch -M main
fi

# Get GitHub username and repo name
read -p "Enter your GitHub username: " GITHUB_USERNAME
read -p "Enter your repository name: " REPO_NAME

# Add remote
echo ""
echo "Adding GitHub remote..."
git remote add origin "https://github.com/${GITHUB_USERNAME}/${REPO_NAME}.git" 2>/dev/null || \
git remote set-url origin "https://github.com/${GITHUB_USERNAME}/${REPO_NAME}.git"

echo ""
echo "Remote configured: https://github.com/${GITHUB_USERNAME}/${REPO_NAME}.git"

# Stage all files
echo ""
echo "Staging files..."
git add .

# Commit
echo ""
read -p "Enter commit message (default: 'Initial commit: PCI-compliant EKS module'): " COMMIT_MSG
COMMIT_MSG=${COMMIT_MSG:-"Initial commit: PCI-compliant EKS module"}

git commit -m "$COMMIT_MSG"

# Push
echo ""
echo "Ready to push to GitHub!"
echo ""
echo "Next steps:"
echo "1. Create the repository on GitHub: https://github.com/new"
echo "2. Run: git push -u origin main"
echo ""
echo "After pushing, follow SETUP.md to configure GitHub Actions"
echo ""
echo "Important: Don't forget to set up:"
echo "  - AWS OIDC provider"
echo "  - IAM role for GitHub Actions"
echo "  - GitHub secret: AWS_ROLE_ARN"
echo "  - S3 backend for Terraform state"
