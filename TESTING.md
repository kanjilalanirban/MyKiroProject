# Testing Guide

Complete guide for testing the PCI-compliant EKS infrastructure.

## Overview

This project includes comprehensive testing at multiple levels:

1. **Static Analysis**: Format, syntax, and security checks
2. **Validation Tests**: Terraform configuration validation
3. **Integration Tests**: Full deployment and functionality testing
4. **Security Tests**: Compliance and security validation

## Quick Start

### Run All Tests Locally

```bash
# Format and validate
cd IaC
terraform fmt -recursive
terraform init -backend=false
terraform validate

# Security scan
docker run --rm -v $(pwd):/src aquasec/tfsec /src

# Validate deployed cluster
./tests/validate.sh <cluster-name>
```

### Run Tests in GitHub Actions

All tests run automatically on push/PR. For manual testing:

1. Go to: Actions → Terraform Test & Validate
2. Click "Run workflow"
3. Review results

## Test Workflows

### 1. Terraform Test & Validate (terraform-test.yml)

**Triggers:**
- Every push to main/develop
- Every pull request
- Manual dispatch

**Tests:**
- ✅ Terraform format check
- ✅ Terraform validation
- ✅ TFLint analysis
- ✅ tfsec security scan
- ✅ Checkov policy checks
- ✅ Cost estimation (Infracost)
- ✅ Test plan generation

**Duration:** ~5 minutes

### 2. Integration Tests (integration-test.yml)

**Triggers:**
- Manual dispatch
- Weekly schedule (Monday 2 AM)

**Tests:**
- ✅ Deploy test cluster
- ✅ Test cluster access
- ✅ Validate node health
- ✅ Test pod deployment
- ✅ Test secrets encryption
- ✅ Test network connectivity
- ✅ Validate RBAC
- ✅ Security validation
- ✅ Cleanup resources

**Duration:** ~30-45 minutes

### 3. Security Scan (security-scan.yml)

**Triggers:**
- Every push to main
- Every pull request
- Weekly schedule (Sunday)

**Tests:**
- ✅ tfsec security analysis
- ✅ Checkov compliance checks
- ✅ SARIF report generation

**Duration:** ~3 minutes

## Test Details

### Static Analysis Tests

#### Format Check
```bash
terraform fmt -check -recursive
```
Ensures consistent code formatting.

#### Validation
```bash
terraform init -backend=false
terraform validate
```
Validates Terraform syntax and configuration.

#### TFLint
```bash
tflint --init
tflint --format compact
```
Lints Terraform code for best practices.

### Security Tests

#### tfsec
```bash
tfsec . --minimum-severity MEDIUM
```
Scans for security issues:
- Unencrypted resources
- Public access
- Missing logging
- Weak policies

#### Checkov
```bash
checkov -d . --framework terraform
```
Policy-as-code validation:
- CIS benchmarks
- PCI DSS requirements
- Best practices

### Integration Tests

#### Cluster Deployment
- Creates test cluster with minimal resources
- Uses test VPC and subnets
- Applies all security configurations

#### Functionality Tests
- **Cluster Access**: Verifies kubectl connectivity
- **Node Health**: Checks all nodes are ready
- **Pod Deployment**: Tests workload deployment
- **Secrets**: Validates encryption at rest
- **Network**: Tests connectivity
- **RBAC**: Validates access controls

#### Security Validation
- **Encryption**: Verifies KMS encryption enabled
- **Logging**: Confirms CloudWatch logs active
- **Endpoints**: Validates private endpoint config
- **Volumes**: Checks EBS encryption

#### Cleanup
- Destroys all test resources
- Verifies complete cleanup
- Prevents resource leaks

## Running Tests Locally

### Prerequisites

```bash
# Install required tools
brew install terraform tflint
brew install awscli kubectl

# Install Docker (for tfsec)
brew install docker

# Install Go (for Terratest)
brew install go
```

### Format and Validate

```bash
cd IaC

# Format code
terraform fmt -recursive

# Initialize
terraform init -backend=false

# Validate
terraform validate
```

### Security Scanning

```bash
cd IaC

# Run tfsec
docker run --rm -v $(pwd):/src aquasec/tfsec /src

# Run Checkov
docker run --rm -v $(pwd):/src bridgecrew/checkov -d /src
```

### Validation Script

```bash
cd IaC/tests

# Make executable
chmod +x validate.sh

# Run validation
./validate.sh <your-cluster-name>
```

### Unit Tests (Terratest)

```bash
cd IaC/tests

# Initialize Go module
go mod init eks-tests

# Install dependencies
go get github.com/gruntwork-io/terratest/modules/terraform
go get github.com/stretchr/testify/assert

# Run tests
go test -v -timeout 30m
```

## GitHub Actions Setup

### Required Secrets

Configure these in GitHub repository settings:

**Required:**
- `AWS_ROLE_ARN`: IAM role for GitHub Actions

**Optional (for integration tests):**
- `TEST_VPC_ID`: VPC for test deployments
- `TEST_SUBNET_IDS`: Subnets for test deployments
- `INFRACOST_API_KEY`: For cost estimation

### Setting Secrets

```bash
# Go to repository settings
https://github.com/YOUR_USERNAME/MyKiroProject/settings/secrets/actions

# Add each secret:
# 1. Click "New repository secret"
# 2. Enter name and value
# 3. Click "Add secret"
```

## Test Results

### Viewing Results

**GitHub Actions:**
1. Go to Actions tab
2. Click on workflow run
3. Review job results

**Artifacts:**
- Terraform plans
- Test reports
- Security scan results

**Job Summaries:**
- Resource counts
- Test pass/fail status
- Security findings

### Understanding Results

#### ✅ Success
All tests passed. Safe to merge/deploy.

#### ⚠️ Warning
Non-critical issues found. Review before proceeding.

#### ❌ Failure
Critical issues found. Must fix before deploying.

## Troubleshooting

### Format Check Fails

```bash
# Fix formatting
terraform fmt -recursive

# Commit changes
git add .
git commit -m "Fix formatting"
```

### Validation Fails

Check error message for:
- Missing required variables
- Invalid resource references
- Syntax errors

### Security Scan Fails

Review findings:
- HIGH/CRITICAL: Must fix
- MEDIUM: Should fix
- LOW: Consider fixing

### Integration Tests Fail

Common issues:
- AWS permissions insufficient
- VPC/subnet configuration
- Resource limits reached
- Timeout (increase in workflow)

### Tests Pass Locally but Fail in CI

Check:
- GitHub secrets configured
- AWS role permissions
- Terraform version matches
- Backend configuration

## Best Practices

### Before Committing

```bash
# 1. Format code
terraform fmt -recursive

# 2. Validate
terraform validate

# 3. Run security scan
docker run --rm -v $(pwd):/src aquasec/tfsec /src

# 4. Commit
git add .
git commit -m "Your message"
git push
```

### Before Deploying

1. ✅ All tests pass in CI
2. ✅ Security scans reviewed
3. ✅ Cost estimate reviewed
4. ✅ PR approved
5. ✅ Integration tests passed

### Regular Testing

- Run integration tests weekly
- Review security scans
- Update test cases for new features
- Monitor test execution time

## Adding New Tests

### Add Validation Test

Edit `.github/workflows/terraform-test.yml`:

```yaml
- name: Your New Test
  run: |
    # Your test commands
```

### Add Integration Test

Edit `.github/workflows/integration-test.yml`:

```yaml
- name: Your New Test
  run: |
    # Your test commands
```

### Add Unit Test

Create `IaC/tests/your_test.go`:

```go
package test

import (
    "testing"
    "github.com/gruntwork-io/terratest/modules/terraform"
)

func TestYourFeature(t *testing.T) {
    // Your test code
}
```

## Continuous Improvement

### Metrics to Track

- Test execution time
- Test pass rate
- Security findings trend
- Cost estimates

### Regular Reviews

- Monthly: Review test coverage
- Quarterly: Update test cases
- Annually: Review testing strategy

## Support

### Documentation
- [Terraform Testing](https://www.terraform.io/docs/language/modules/testing.html)
- [Terratest](https://terratest.gruntwork.io/)
- [tfsec](https://aquasecurity.github.io/tfsec/)
- [Checkov](https://www.checkov.io/)

### Getting Help

- Check workflow logs
- Review test documentation
- Open GitHub issue
- Consult AWS documentation

## Summary

This testing framework ensures:
- ✅ Code quality and consistency
- ✅ Security compliance
- ✅ Functionality validation
- ✅ Cost awareness
- ✅ Automated validation
- ✅ Continuous monitoring

Run tests early and often for best results!
