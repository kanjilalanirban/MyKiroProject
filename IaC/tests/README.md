# Infrastructure Testing

This directory contains tests for the EKS infrastructure.

## Test Types

### 1. Terraform Validation Tests
- Format checking
- Syntax validation
- Configuration validation

### 2. Security Tests
- tfsec scanning
- Checkov policy checks
- Compliance validation

### 3. Integration Tests
- Full cluster deployment
- Functionality testing
- Security validation
- Cleanup

### 4. Unit Tests (Terratest)
- Go-based infrastructure tests
- Resource validation
- Output verification

## Running Tests Locally

### Validation Tests

```bash
cd IaC

# Format check
terraform fmt -check -recursive

# Validate configuration
terraform init -backend=false
terraform validate

# Security scan
docker run --rm -v $(pwd):/src aquasec/tfsec /src
```

### Integration Tests

```bash
# Run validation script
cd IaC/tests
./validate.sh <cluster-name>
```

### Unit Tests (Terratest)

```bash
cd IaC/tests

# Install dependencies
go mod init eks-tests
go get github.com/gruntwork-io/terratest/modules/terraform
go get github.com/stretchr/testify/assert

# Run tests
go test -v -timeout 30m
```

## GitHub Actions Workflows

### terraform-test.yml
Runs on every push and PR:
- Terraform format check
- Terraform validation
- TFLint
- Security scanning (tfsec, Checkov)
- Cost estimation (Infracost)
- Test plan generation

### integration-test.yml
Runs on manual trigger or weekly:
- Deploys test cluster
- Tests cluster functionality
- Validates security settings
- Cleans up resources

## Test Coverage

### Infrastructure Tests
- ✅ Cluster creation
- ✅ Node group configuration
- ✅ Security group rules
- ✅ IAM roles and policies
- ✅ KMS encryption
- ✅ CloudWatch logging
- ✅ OIDC provider

### Security Tests
- ✅ Secrets encryption enabled
- ✅ EBS volume encryption
- ✅ Private endpoint configuration
- ✅ Logging enabled
- ✅ Security group rules
- ✅ IAM least privilege
- ✅ Network isolation

### Functionality Tests
- ✅ Cluster accessibility
- ✅ Node health
- ✅ Pod deployment
- ✅ Network connectivity
- ✅ RBAC configuration
- ✅ Secrets management

## Test Results

Test results are available in:
- GitHub Actions workflow runs
- Uploaded artifacts (plans, reports)
- Job summaries

## Adding New Tests

### Add Terraform Validation Test
Edit `.github/workflows/terraform-test.yml`

### Add Integration Test
Edit `.github/workflows/integration-test.yml`

### Add Unit Test
Create new test file in `IaC/tests/` with `_test.go` suffix

## Troubleshooting

### Tests Failing Locally
- Ensure AWS credentials are configured
- Check Terraform version matches workflow
- Verify all required tools are installed

### Tests Failing in CI
- Check GitHub secrets are configured
- Verify AWS permissions
- Review workflow logs

### Integration Tests Timeout
- Increase timeout in workflow
- Check AWS service limits
- Verify network connectivity

## Best Practices

1. **Run tests before pushing**
   ```bash
   terraform fmt -recursive
   terraform validate
   ```

2. **Review security scan results**
   - Address HIGH and CRITICAL findings
   - Document accepted risks

3. **Test in isolated environment**
   - Use separate AWS account for testing
   - Clean up resources after tests

4. **Monitor costs**
   - Review Infracost reports
   - Clean up test resources promptly

5. **Keep tests updated**
   - Update tests when infrastructure changes
   - Add tests for new features
