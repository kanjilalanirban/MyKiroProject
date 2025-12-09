# PCI-Compliant EKS Terraform Module

This Terraform module deploys an Amazon EKS cluster with security configurations aligned to PCI DSS requirements.

## PCI Compliance Features

### Encryption
- **Secrets Encryption**: Kubernetes secrets encrypted at rest using AWS KMS with automatic key rotation
- **EBS Encryption**: All node volumes encrypted using dedicated KMS keys
- **Data in Transit**: TLS encryption for all cluster communications

### Logging & Monitoring
- **Control Plane Logs**: All EKS control plane logs enabled (API, audit, authenticator, controller manager, scheduler)
- **CloudWatch Integration**: Centralized logging with configurable retention (default 90 days)
- **Audit Trails**: Complete audit logging for compliance requirements

### Network Security
- **Private Endpoints**: API server can be configured for private-only access
- **Security Groups**: Strict ingress/egress rules with least privilege
- **Network Isolation**: Nodes deployed in private subnets (recommended)
- **CIDR Restrictions**: Configurable allowed IP ranges for cluster access

### Access Control
- **IAM Roles**: Separate roles for cluster and node groups with minimal permissions
- **IRSA Support**: IAM Roles for Service Accounts for pod-level permissions
- **IMDSv2**: Enforced use of Instance Metadata Service v2

### Infrastructure Hardening
- **Encrypted Volumes**: All EBS volumes encrypted by default
- **No Public IPs**: Nodes configured without public IP addresses (configurable)
- **SSH Hardening**: Root login disabled, password authentication disabled
- **Automatic Updates**: Security patches applied automatically

## Prerequisites

- Terraform >= 1.0
- AWS CLI configured with appropriate credentials
- VPC with private subnets
- KMS permissions for encryption key management

## Usage

```hcl
module "eks_pci_compliant" {
  source = "./path-to-module"

  cluster_name       = "my-pci-cluster"
  environment        = "production"
  kubernetes_version = "1.28"

  vpc_id     = "vpc-xxxxx"
  subnet_ids = ["subnet-xxxxx", "subnet-yyyyy"]

  enable_public_access = false
  allowed_cidr_blocks  = ["10.0.0.0/8"]

  desired_size   = 3
  min_size       = 2
  max_size       = 5
  instance_types = ["t3.medium"]

  associate_public_ip_address = false
  log_retention_days          = 90
}
```

## Configuration

Copy `terraform.tfvars.example` to `terraform.tfvars` and update with your values:

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your configuration
```

## Deployment

```bash
# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply the configuration
terraform apply
```

## Post-Deployment Steps

### 1. Configure kubectl

```bash
aws eks update-kubeconfig --name <cluster-name> --region <region>
```

### 2. Install Essential Add-ons

```bash
# AWS Load Balancer Controller
# Cluster Autoscaler
# Container Insights
# Pod Security Standards
```

### 3. Apply Network Policies

Implement Kubernetes Network Policies to control pod-to-pod communication.

### 4. Enable Pod Security Standards

```bash
kubectl label namespace default pod-security.kubernetes.io/enforce=restricted
```

## PCI DSS Requirements Mapping

| Requirement | Implementation |
|-------------|----------------|
| 2.2 - Secure Configuration | Hardened node configuration, IMDSv2, SSH hardening |
| 3.4 - Encryption at Rest | KMS encryption for secrets and EBS volumes |
| 4.1 - Encryption in Transit | TLS for all communications |
| 8.2 - Authentication | IAM roles, IRSA for service accounts |
| 10.2 - Audit Logging | CloudWatch logs for all control plane activities |
| 10.7 - Log Retention | 90-day log retention (configurable) |

## Security Best Practices

1. **Network Isolation**: Deploy in private subnets with NAT gateway
2. **Bastion Host**: Use bastion host or AWS Systems Manager for node access
3. **Regular Updates**: Keep Kubernetes version current
4. **Monitoring**: Enable Container Insights and CloudWatch alarms
5. **Backup**: Implement regular etcd backups
6. **Secrets Management**: Use AWS Secrets Manager or HashiCorp Vault
7. **Image Scanning**: Scan container images for vulnerabilities
8. **RBAC**: Implement strict role-based access control

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| cluster_name | Name of the EKS cluster | string | - | yes |
| environment | Environment name | string | - | yes |
| vpc_id | VPC ID | string | - | yes |
| subnet_ids | List of subnet IDs | list(string) | - | yes |
| allowed_cidr_blocks | Allowed CIDR blocks | list(string) | - | yes |
| kubernetes_version | Kubernetes version | string | "1.28" | no |
| enable_public_access | Enable public API endpoint | bool | false | no |
| log_retention_days | Log retention in days | number | 90 | no |

## Outputs

| Name | Description |
|------|-------------|
| cluster_endpoint | EKS cluster endpoint |
| cluster_security_group_id | Cluster security group ID |
| node_security_group_id | Node security group ID |
| kms_key_arn | KMS key ARN for secrets |
| oidc_provider_arn | OIDC provider ARN for IRSA |

## Compliance Notes

This module provides a foundation for PCI compliance but does not guarantee full compliance. Additional requirements include:

- Regular vulnerability scanning
- Penetration testing
- Security awareness training
- Incident response procedures
- Change management processes
- Physical security controls

Consult with your QSA (Qualified Security Assessor) for complete compliance validation.

## License

MIT
