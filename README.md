# MyKiroProject

This repository contains Infrastructure as Code (IaC) for deploying a PCI-compliant Amazon EKS cluster.

## Repository Structure

```
MyKiroProject/
├── IaC/                          # Terraform infrastructure code
│   ├── main.tf                   # EKS cluster configuration
│   ├── iam.tf                    # IAM roles and policies
│   ├── security_groups.tf        # Network security
│   ├── node_groups.tf            # Worker node configuration
│   ├── irsa.tf                   # OIDC provider for IRSA
│   ├── variables.tf              # Input variables
│   ├── outputs.tf                # Output values
│   ├── user_data.sh              # Node bootstrap script
│   ├── backend.tf.example        # S3 backend example
│   ├── terraform.tfvars.example  # Variables example
│   ├── README.md                 # Detailed documentation
│   └── SETUP.md                  # Setup instructions
├── .github/
│   └── workflows/                # GitHub Actions workflows
│       ├── terraform-deploy.yml  # Main deployment workflow
│       ├── terraform-plan-on-pr.yml  # PR plan workflow
│       └── security-scan.yml     # Security scanning
└── scripts/
    └── setup-github.sh           # GitHub setup helper

```

## Quick Start

1. **Review the Infrastructure Code**
   ```bash
   cd IaC
   cat README.md
   ```

2. **Configure Your Environment**
   ```bash
   cd IaC
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your values
   ```

3. **Set Up GitHub Actions**
   - Follow the instructions in `IaC/SETUP.md`
   - Configure AWS OIDC provider
   - Set GitHub secrets

4. **Deploy**
   - Push to main branch for automatic deployment
   - Or use manual workflow dispatch

## Features

- **PCI DSS Compliant**: Security configurations aligned with PCI requirements
- **Encrypted**: KMS encryption for secrets and EBS volumes
- **Logged**: Complete audit logging to CloudWatch
- **Secure**: Private endpoints, strict security groups, IAM roles
- **Automated**: GitHub Actions for CI/CD
- **Scanned**: Automated security scanning with tfsec and Checkov

## Documentation

- [Infrastructure Documentation](IaC/README.md)
- [Setup Guide](IaC/SETUP.md)

## GitHub Actions Workflows

- **Deploy EKS Cluster**: Automated deployment on push to main
- **Terraform Plan on PR**: Preview changes in pull requests
- **Security Scan**: Weekly security scans with tfsec and Checkov

## Security

This infrastructure implements:
- Encryption at rest and in transit
- Network isolation
- Audit logging
- IAM least privilege
- Automated security updates
- Regular security scanning

## License

MIT
