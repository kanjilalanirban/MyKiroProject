#!/bin/bash

# Quick start script for MyKiroProject
set -e

clear
echo "=========================================="
echo "   MyKiroProject - Quick Start Setup"
echo "=========================================="
echo ""
echo "This script will help you push your code to GitHub"
echo "and set up automated EKS deployment."
echo ""
echo "Choose your setup method:"
echo ""
echo "1) GitHub CLI (Recommended - easiest)"
echo "2) Manual with Personal Access Token"
echo "3) Show me the manual steps"
echo "4) Exit"
echo ""
read -p "Enter your choice (1-4): " CHOICE

case $CHOICE in
    1)
        echo ""
        echo "Using GitHub CLI..."
        if ! command -v gh &> /dev/null; then
            echo ""
            echo "GitHub CLI is not installed."
            read -p "Install it now with Homebrew? (y/n): " INSTALL
            if [ "$INSTALL" = "y" ] || [ "$INSTALL" = "Y" ]; then
                brew install gh
            else
                echo "Please install GitHub CLI manually: brew install gh"
                exit 1
            fi
        fi
        ./setup-github-repo.sh
        ;;
    2)
        echo ""
        echo "Using Personal Access Token..."
        ./setup-github-manual.sh
        ;;
    3)
        echo ""
        echo "Opening manual setup guide..."
        if command -v open &> /dev/null; then
            open GITHUB_SETUP.md
        else
            cat GITHUB_SETUP.md
        fi
        ;;
    4)
        echo "Exiting..."
        exit 0
        ;;
    *)
        echo "Invalid choice. Please run the script again."
        exit 1
        ;;
esac

echo ""
echo "=========================================="
echo "Setup complete!"
echo "=========================================="
echo ""
echo "📚 Next, read the setup guide:"
echo "   cat GITHUB_SETUP.md"
echo ""
echo "📖 Or view infrastructure docs:"
echo "   cd IaC && cat README.md"
echo ""
