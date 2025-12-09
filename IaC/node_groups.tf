# EKS Node Group with encrypted EBS volumes
resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.cluster_name}-node-group"
  node_role_arn   = aws_iam_role.node_group.arn
  subnet_ids      = var.subnet_ids
  version         = var.kubernetes_version

  scaling_config {
    desired_size = var.desired_size
    max_size     = var.max_size
    min_size     = var.min_size
  }

  update_config {
    max_unavailable = 1
  }

  instance_types = var.instance_types
  capacity_type  = var.capacity_type
  disk_size      = var.disk_size

  # Enable encryption for node group volumes
  launch_template {
    id      = aws_launch_template.node_group.id
    version = "$Latest"
  }

  depends_on = [
    aws_iam_role_policy_attachment.node_group_policy,
    aws_iam_role_policy_attachment.node_group_cni_policy,
    aws_iam_role_policy_attachment.node_group_registry_policy,
  ]

  tags = {
    Name        = "${var.cluster_name}-node-group"
    Environment = var.environment
    Compliance  = "PCI-DSS"
  }
}

# Launch template for encrypted EBS volumes
resource "aws_launch_template" "node_group" {
  name_prefix = "${var.cluster_name}-node-"
  description = "Launch template for EKS nodes with encrypted volumes"

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = var.disk_size
      volume_type           = "gp3"
      encrypted             = true
      kms_key_id            = aws_kms_key.ebs.arn
      delete_on_termination = true
    }
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  monitoring {
    enabled = true
  }

  network_interfaces {
    associate_public_ip_address = var.associate_public_ip_address
    security_groups             = [aws_security_group.node.id]
    delete_on_termination       = true
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name        = "${var.cluster_name}-node"
      Environment = var.environment
      Compliance  = "PCI-DSS"
    }
  }

  tag_specifications {
    resource_type = "volume"

    tags = {
      Name        = "${var.cluster_name}-node-volume"
      Environment = var.environment
      Compliance  = "PCI-DSS"
    }
  }

  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    cluster_name        = var.cluster_name
    cluster_endpoint    = aws_eks_cluster.main.endpoint
    cluster_ca          = aws_eks_cluster.main.certificate_authority[0].data
  }))

  tags = {
    Name        = "${var.cluster_name}-launch-template"
    Environment = var.environment
    Compliance  = "PCI-DSS"
  }
}

# KMS key for EBS encryption
resource "aws_kms_key" "ebs" {
  description             = "EKS node EBS encryption key"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  tags = {
    Name        = "${var.cluster_name}-ebs-key"
    Environment = var.environment
    Compliance  = "PCI-DSS"
  }
}

resource "aws_kms_alias" "ebs" {
  name          = "alias/${var.cluster_name}-ebs"
  target_key_id = aws_kms_key.ebs.key_id
}
