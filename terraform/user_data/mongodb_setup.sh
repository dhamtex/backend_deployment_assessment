#!/bin/bash
set -euxo pipefail

# Configure MongoDB 7.0 repository
cat <<EOF > /etc/yum.repos.d/mongodb-org-7.0.repo
[mongodb-org-7.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/amazon/2/mongodb-org/7.0/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://pgp.mongodb.com/server-7.0.asc
EOF

# Install MongoDB
yum install -y mongodb-org

# Allow connections from the private VPC.
# Security group rules restrict access to the Backend EC2.
sed -i 's/^  bindIp: 127.0.0.1/  bindIp: 0.0.0.0/' /etc/mongod.conf

# Start MongoDB
systemctl enable mongod
systemctl start mongod

# Verify MongoDB service
systemctl status mongod --no-pager