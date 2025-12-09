#!/bin/bash
set -o xtrace

# Bootstrap the node
/etc/eks/bootstrap.sh ${cluster_name} \
  --b64-cluster-ca ${cluster_ca} \
  --apiserver-endpoint ${cluster_endpoint}

# Enable audit logging
echo "audit=1" >> /etc/sysctl.conf
sysctl -p

# Harden SSH (PCI requirement)
sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
systemctl restart sshd

# Enable automatic security updates
yum install -y yum-cron
sed -i 's/apply_updates = no/apply_updates = yes/' /etc/yum/yum-cron.conf
systemctl enable yum-cron
systemctl start yum-cron
