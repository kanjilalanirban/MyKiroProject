#!/bin/bash

# Validation script for EKS infrastructure
set -e

echo "=========================================="
echo "EKS Infrastructure Validation"
echo "=========================================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if cluster name is provided
if [ -z "$1" ]; then
    echo -e "${RED}Error: Cluster name required${NC}"
    echo "Usage: $0 <cluster-name>"
    exit 1
fi

CLUSTER_NAME=$1
REGION=${AWS_REGION:-us-east-1}

echo "Cluster: $CLUSTER_NAME"
echo "Region: $REGION"
echo ""

# Function to print test result
print_result() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓${NC} $2"
    else
        echo -e "${RED}✗${NC} $2"
        FAILED=1
    fi
}

FAILED=0

# Test 1: Cluster exists and is active
echo "Test 1: Checking cluster status..."
CLUSTER_STATUS=$(aws eks describe-cluster --name $CLUSTER_NAME --region $REGION --query 'cluster.status' --output text 2>/dev/null || echo "NOT_FOUND")
if [ "$CLUSTER_STATUS" = "ACTIVE" ]; then
    print_result 0 "Cluster is active"
else
    print_result 1 "Cluster status: $CLUSTER_STATUS"
fi

# Test 2: Secrets encryption enabled
echo "Test 2: Checking secrets encryption..."
ENCRYPTION=$(aws eks describe-cluster --name $CLUSTER_NAME --region $REGION --query 'cluster.encryptionConfig[0].resources[0]' --output text 2>/dev/null || echo "NONE")
if [ "$ENCRYPTION" = "secrets" ]; then
    print_result 0 "Secrets encryption enabled"
else
    print_result 1 "Secrets encryption not enabled"
fi

# Test 3: Logging enabled
echo "Test 3: Checking cluster logging..."
LOGGING=$(aws eks describe-cluster --name $CLUSTER_NAME --region $REGION --query 'cluster.logging.clusterLogging[0].enabled' --output text 2>/dev/null || echo "False")
if [ "$LOGGING" = "True" ]; then
    print_result 0 "Cluster logging enabled"
else
    print_result 1 "Cluster logging not enabled"
fi

# Test 4: Private endpoint enabled
echo "Test 4: Checking private endpoint..."
PRIVATE_ENDPOINT=$(aws eks describe-cluster --name $CLUSTER_NAME --region $REGION --query 'cluster.resourcesVpcConfig.endpointPrivateAccess' --output text 2>/dev/null || echo "False")
if [ "$PRIVATE_ENDPOINT" = "True" ]; then
    print_result 0 "Private endpoint enabled"
else
    print_result 1 "Private endpoint not enabled"
fi

# Test 5: Node groups exist
echo "Test 5: Checking node groups..."
NODE_GROUPS=$(aws eks list-nodegroups --cluster-name $CLUSTER_NAME --region $REGION --query 'nodegroups' --output text 2>/dev/null || echo "")
if [ -n "$NODE_GROUPS" ]; then
    print_result 0 "Node groups exist: $NODE_GROUPS"
else
    print_result 1 "No node groups found"
fi

# Test 6: Nodes are ready
echo "Test 6: Checking node status..."
if command -v kubectl &> /dev/null; then
    aws eks update-kubeconfig --name $CLUSTER_NAME --region $REGION > /dev/null 2>&1
    READY_NODES=$(kubectl get nodes --no-headers 2>/dev/null | grep -c " Ready " || echo "0")
    if [ "$READY_NODES" -gt 0 ]; then
        print_result 0 "Ready nodes: $READY_NODES"
    else
        print_result 1 "No ready nodes found"
    fi
else
    echo -e "${YELLOW}⊘${NC} kubectl not installed, skipping node check"
fi

# Test 7: KMS key exists and is enabled
echo "Test 7: Checking KMS encryption key..."
KMS_KEY_ARN=$(aws eks describe-cluster --name $CLUSTER_NAME --region $REGION --query 'cluster.encryptionConfig[0].provider.keyArn' --output text 2>/dev/null || echo "")
if [ -n "$KMS_KEY_ARN" ]; then
    KMS_KEY_ID=$(echo $KMS_KEY_ARN | awk -F'/' '{print $NF}')
    KMS_STATUS=$(aws kms describe-key --key-id $KMS_KEY_ID --region $REGION --query 'KeyMetadata.KeyState' --output text 2>/dev/null || echo "UNKNOWN")
    if [ "$KMS_STATUS" = "Enabled" ]; then
        print_result 0 "KMS key is enabled"
    else
        print_result 1 "KMS key status: $KMS_STATUS"
    fi
else
    print_result 1 "KMS key not found"
fi

# Test 8: CloudWatch log group exists
echo "Test 8: Checking CloudWatch logs..."
LOG_GROUP="/aws/eks/$CLUSTER_NAME/cluster"
LOG_EXISTS=$(aws logs describe-log-groups --log-group-name-prefix $LOG_GROUP --region $REGION --query 'logGroups[0].logGroupName' --output text 2>/dev/null || echo "")
if [ "$LOG_EXISTS" = "$LOG_GROUP" ]; then
    print_result 0 "CloudWatch log group exists"
else
    print_result 1 "CloudWatch log group not found"
fi

# Test 9: Security groups configured
echo "Test 9: Checking security groups..."
SG_IDS=$(aws eks describe-cluster --name $CLUSTER_NAME --region $REGION --query 'cluster.resourcesVpcConfig.securityGroupIds' --output text 2>/dev/null || echo "")
if [ -n "$SG_IDS" ]; then
    print_result 0 "Security groups configured"
else
    print_result 1 "No security groups found"
fi

# Test 10: OIDC provider exists
echo "Test 10: Checking OIDC provider..."
OIDC_ISSUER=$(aws eks describe-cluster --name $CLUSTER_NAME --region $REGION --query 'cluster.identity.oidc.issuer' --output text 2>/dev/null || echo "")
if [ -n "$OIDC_ISSUER" ]; then
    print_result 0 "OIDC provider configured"
else
    print_result 1 "OIDC provider not found"
fi

echo ""
echo "=========================================="
if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed!${NC}"
    exit 1
fi
