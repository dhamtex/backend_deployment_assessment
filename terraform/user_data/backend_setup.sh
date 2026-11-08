#!/bin/bash

set -euxo pipefail

# Update system packages
yum update -y

# Install Docker
amazon-linux-extras install docker -y

# Start Docker
systemctl enable docker
systemctl start docker

# Install Docker Compose
DOCKER_COMPOSE_VERSION="v2.29.7"

mkdir -p /usr/local/lib/docker/cli-plugins

curl -SL \
  "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-linux-x86_64" \
  -o /usr/local/lib/docker/cli-plugins/docker-compose

chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

# Verify installation
docker --version
docker compose version






#!/bin/bash

set -Eeuo pipefail

# Log all output
exec > >(tee -a /var/log/backend-setup.log) 2>&1

echo "===== Backend setup started: $(date) ====="

# Log failures
trap 'echo "ERROR: Setup failed at line $LINENO. Exit code: $?"' ERR

# Retry commands to handle temporary repository/network failures
retry() {
    local attempts=5
    local delay=10
    local count=1

    until "$@"; do
        if [ "$count" -ge "$attempts" ]; then
            echo "ERROR: Command failed after $attempts attempts: $*"
            return 1
        fi

        echo "Attempt $count failed. Retrying in ${delay}s..."
        sleep "$delay"

        count=$((count + 1))
        delay=$((delay + 10))
    done
}

# Refresh package metadata
echo "Refreshing YUM repositories..."
retry yum clean all
retry yum makecache

# Install curl
echo "Installing curl..."
retry yum install -y curl

# Install Docker
echo "Installing Docker..."
retry amazon-linux-extras install docker -y

# Enable and start Docker
echo "Starting Docker..."
systemctl enable docker
systemctl start docker

# Install Docker Compose
DOCKER_COMPOSE_VERSION="v2.29.7"

ARCH=$(uname -m)

case "$ARCH" in
    x86_64)
        COMPOSE_ARCH="x86_64"
        ;;
    aarch64)
        COMPOSE_ARCH="aarch64"
        ;;
    *)
        echo "Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

PLUGIN_DIR="/usr/local/lib/docker/cli-plugins"
PLUGIN_PATH="${PLUGIN_DIR}/docker-compose"

echo "Installing Docker Compose ${DOCKER_COMPOSE_VERSION}..."

mkdir -p "$PLUGIN_DIR"

curl --fail --location \
    --retry 5 \
    --retry-all-errors \
    --connect-timeout 15 \
    --max-time 300 \
    "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-linux-${COMPOSE_ARCH}" \
    -o "${PLUGIN_PATH}.tmp"

chmod 755 "${PLUGIN_PATH}.tmp"
mv "${PLUGIN_PATH}.tmp" "$PLUGIN_PATH"

# Give deployment user Docker access if it exists
if id deploy &>/dev/null; then
    usermod -aG docker deploy
    echo "Added deploy user to Docker group."
fi

# Verify installations
echo "Verifying Docker installation..."
docker --version
docker compose version

systemctl is-active --quiet docker

echo "===== Backend setup completed successfully: $(date) ====="
