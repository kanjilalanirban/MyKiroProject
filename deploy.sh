#!/bin/bash

# Interactive deployment script for PCI-compliant EKS cluster
set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

clear
echo -e "${BLUE}=========================================="
echo "  PCI-Compliant EKS Deployment Wizard"
echo -e "==========================================${NC}"
echo ""

# Function to print status
print_status() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

# Check prerequisites
echo -e "${BLUE}Step 1: Checking Prerequisites${NC}"
echo "================================"
echo ""

# Check AWS CLI
if command -v aws &> /dev/null; then
    print_status "AWS CLI installed"
else
    print_error "AWS CLI not installed"
    echo "Run: brew install awscli"
    exit 1
fi

# Check Terraform
if command -v terraform &> /dev/null; then
    print_status "Terraform installed"
else
    print_warning "Terraform not installed"
    read -p "Install Terraform now? (y/n): " INSTALL_TF
    if [ "$INSTALL_TF" = "y" ]; then
        brew install terraform
        print_status "Terraform installed"
    else
        print_error "Terraform required"
        exit 1
    fi
fi

# Check kubectl
if command -v kubectl &> /dev/null; then
    print_status "kubectl installed"
else
    print_warning "kubectl not installed"
    read -p "Install kubectl now? (y/n): " INSTALL_KB
    if [ "$INSTALL_KB" = "y" ]; then
        brew install kubectl
        print_status "kubectl installed"
    else
        print_warning "kubectl recommended but not required for deployment"
    fi
fi

echo ""
echo -e "${BLUE}Step 2: AWS Configuration${NC}"
echo "=========================="
echo ""

# Check AWS credentials
if aws sts get-caller-identity &> /dev/null; then
    CALLER_IDENTITY=$(aws sts get-caller-identity)
    ACCOUNT_ID=$(echo $CALLER_IDENTITY | jq -r '.Account')
    USER_ARN=$(echo $CALLER_IDENTITY | jq -r '.Arn')
    
    print_status "AWS credentials configured"
    echo "  Account ID: $ACCOUNT_ID"
    echo "  User: $USER_ARN"
    
    # Check if root user
    if echo "$USER_ARN" | grep -q ":root"; then
        echo ""
        print_error "YOU ARE USING ROOT CREDENTIALS!"
        print_error "This is a SERIOUS SECURITY RISK and violates PCI compliance!"
        echo ""
        echo "Please:"
        echo "1. Create an IAM user with admin permissions"
        echo "2. Create access keys for that user"
        echo "3. Run: aws configure"
        echo "4. Enter the IAM user credentials"
        echo ""
        read -p "Do you want to continue anyway? (NOT RECOMMENDED) (y/n): " CONTINUE_ROOT
        if [ "$CONTINUE_ROOT" != "y" ]; then
            echo "Good choice! Please create an IAM user first."
            echo "See DEPLOYMENT_STEPS.md for instructions."
            exit 1
        fi
        print_warning "Continuing with root credentials (NOT RECOMMENDED)"
    fi
else
    print_error "AWS credentials not configured"
    echo ""
    echo "Please run: aws configure"
    echo "You'll need:"
    echo "  - AWS Access Key ID"
    echo "  - AWS Secret Access Key"
    echo "  - Default region (us-east-1)"
    echo ""
    read -p "Configure AWS now? (y/n): " CONFIG_AWS
    if [ "$CONFIG_AWS" = "y" ]; then
        aws configure
        print_status "AWS configured"
    else
        exit 1
    fi
fi

echo ""
echo -e "${BLUE}Step 3: OIDC and IAM Setup${NC}"
echo "==========================="
echo ""

print_info "This will create:"
echo "  - OIDC provider for GitHub Actions"
echo "  - IAM role for secure deployments"
echo "  - S3 bucket for Terraform state"
echo "  - DynamoDB table for state locking"
echo ""

read -p "Run OIDC setup script? (y/n): " RUN_OIDC
if [ "$RUN_OIDC" = "y" ]; then
    ./scripts/setup-aws-oidc.sh
    echo ""
    print_status "OIDC setup complete"
    echo ""
    print_warning "IMPORTANT: Copy the AWS_ROLE_ARN from above!"
    echo ""
    read -p "Press Enter after you've copied the role ARN..."
else
    print_warning "Skipping OIDC setup"
fi

echo ""
echo -e "${BLUE}Step 4: GitHub Secret Configuration${NC}"
echo "===================================="
echo ""

print_info "Add the AWS_ROLE_ARN to GitHub:"
echo "1. Go to: https://github.com/kanjilalanirban/MyKiroProject/settings/secrets/actions"
echo "2. Click 'New repository secret'"
echo "3. Name: AWS_ROLE_ARN"
echo "4. Value: (paste the ARN from above)"
echo "5. Click 'Add secret'"
echo ""

read -p "Have you added the GitHub secret? (y/n): " ADDED_SECRET
if [ "$ADDED_SECRET" != "y" ]; then
    print_warning "Please add the GitHub secret before continuing"
    echo "You can continue the deployment later by running this script again."
    exit 0
fi

echo ""
echo -e "${BLUE}Step 5: VPC and Subnet Configuration${NC}"
echo "====================================="
echo ""

print_info "Getting VPC information..."
echo ""

# Try to get default VPC
DEFAULT_VPC=$(aws ec2 describe-vpcs --filters "Name=isDefault,Values=true" --query "Vpcs[0].VpcId" --output text 2>/dev/null || echo "")

if [ -n "$DEFAULT_VPC" ] && [ "$DEFAULT_VPC" != "None" ]; then
    print_status "Found default VPC: $DEFAULT_VPC"
    echo ""
    echo "Subnets in default VPC:"
    aws ec2 describe-subnets --filters "Name=vpc-id,Values=$DEFAULT_VPC" --query "Subnets[*].[SubnetId,AvailabilityZone,CidrBlock]" --output table
    echo ""
    
    read -p "Use default VPC for deployment? (y/n): " USE_DEFAULT
    if [ "$USE_DEFAULT" = "y" ]; then
        VPC_ID=$DEFAULT_VPC
        SUBNET_IDS=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --query "Subnets[*].SubnetId" --output json | jq -r '. | @json')
        print_status "Using default VPC"
    else
        echo ""
        read -p "Enter VPC ID: " VPC_ID
        read -p "Enter subnet IDs (comma-separated): " SUBNET_INPUT
        SUBNET_IDS=$(echo "[$SUBNET_INPUT]" | sed 's/,/","/g' | sed 's/\[/["/' | sed 's/\]/"]/')
    fi
else
    print_warning "No default VPC found"
    echo ""
    echo "You need to provide:"
    read -p "VPC ID: " VPC_ID
    read -p "Subnet IDs (comma-separated): " SUBNET_INPUT
    SUBNET_IDS=$(echo "[$SUBNET_INPUT]" | sed 's/,/","/g' | sed 's/\[/["/' | sed 's/\]/"]/')
fi

echo ""
echo -e "${BLUE}Step 6: Cluster Configuration${NC}"
echo "=============================="
echo ""

read -p "Cluster name [my-pci-eks]: " CLUSTER_NAME
CLUSTER_NAME=${CLUSTER_NAME:-my-pci-eks}

read -p "Environment [production]: " ENVIRONMENT
ENVIRONMENT=${ENVIRONMENT:-production}

read -p "Number of nodes [2]: " NODE_COUNT
NODE_COUNT=${NODE_COUNT:-2}

read -p "Instance type [t3.small]: " INSTANCE_TYPE
INSTANCE_TYPE=${INSTANCE_TYPE:-t3.small}

echo ""
echo -e "${BLUE}Step 7: Configure Terraform Files${NC}"
echo "=================================="
echo ""

cd IaC

# Configure backend
if [ ! -f backend.tf ]; then
    cp backend.tf.example backend.tf
    BUCKET_NAME="terraform-state-${ACCOUNT_ID}-eks"
    sed -i.bak "s/your-terraform-state-bucket/${BUCKET_NAME}/" backend.tf
    rm backend.tf.bak
    print_status "Backend configured"
else
    print_status "Backend already configured"
fi

# Configure variables
cat > terraform.tfvars <<EOF
cluster_name    = "${CLUSTER_NAME}"
environment     = "${ENVIRONMENT}"
kubernetes_version = "1.28"

vpc_id     = "${VPC_ID}"
subnet_ids = ${SUBNET_IDS}

allowed_cidr_blocks  = ["10.0.0.0/8"]
enable_public_access = false

desired_size   = ${NODE_COUNT}
min_size       = 1
max_size       = $((NODE_COUNT + 1))
instance_types = ["${INSTANCE_TYPE}"]

associate_public_ip_address = false
log_retention_days          = 90
EOF

print_status "Variables configured"

echo ""
echo -e "${BLUE}Step 8: Deployment Method${NC}"
echo "========================="
echo ""

echo "Choose deployment method:"
echo "1) Deploy via GitHub Actions (Recommended)"
echo "2) Deploy locally with Terraform"
echo "3) Exit and deploy manually later"
echo ""

read -p "Enter choice (1-3): " DEPLOY_METHOD

case $DEPLOY_METHOD in
    1)
        echo ""
        print_info "Deploying via GitHub Actions..."
        cd ..
        git add IaC/backend.tf
        git commit -m "Configure Terraform backend for deployment"
        git push origin main
        echo ""
        print_status "Pushed to GitHub!"
        echo ""
        print_info "Monitor deployment at:"
        echo "https://github.com/kanjilalanirban/MyKiroProject/actions"
        echo ""
        print_warning "Note: terraform.tfvars is NOT committed (contains sensitive data)"
        ;;
    2)
        echo ""
        print_info "Deploying locally..."
        terraform init
        terraform plan
        echo ""
        read -p "Apply this plan? (y/n): " APPLY
        if [ "$APPLY" = "y" ]; then
            terraform apply
            print_status "Deployment complete!"
        else
            print_info "Plan saved. Run 'terraform apply' when ready."
        fi
        ;;
    3)
        echo ""
        print_info "Configuration saved. You can deploy later by:"
        echo "  cd IaC"
        echo "  terraform init"
        echo "  terraform apply"
        ;;
esac

echo ""
echo -e "${GREEN}=========================================="
echo "  Deployment Wizard Complete!"
echo -e "==========================================${NC}"
echo ""
echo "Next steps:"
echo "1. Monitor deployment (if using GitHub Actions)"
echo "2. Configure kubectl: aws eks update-kubeconfig --name ${CLUSTER_NAME}"
echo "3. Verify cluster: kubectl get nodes"
echo "4. Run validation: ./IaC/tests/validate.sh ${CLUSTER_NAME}"
echo ""
echo "Documentation:"
echo "  - DEPLOYMENT_STEPS.md - Detailed steps"
echo "  - SECURE_DEPLOYMENT.md - Security guide"
echo "  - TESTING.md - Testing guide"
echo ""
