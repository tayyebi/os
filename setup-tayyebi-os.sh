#!/bin/sh
set -e
set -u
set -o pipefail

# Logging
log() { echo "[setup-tayyebi-os] $@"; }

# Ensure running as root
if [ "$(id -u)" -ne 0 ]; then
  log "ERROR: Must be run as root." >&2
  exit 1
fi

# Update and install Docker
log "Updating APK and installing Docker..."
apk update
apk add docker
rc-update add docker boot
service docker start

# Install Portainer
PORTAINER_DATA="/opt/portainer"
mkdir -p "$PORTAINER_DATA"

if ! docker ps | grep -q portainer; then
  log "Installing Portainer..."
  docker run -d \
    --name=portainer \
    --restart=always \
    -p 9000:9000 \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v "$PORTAINER_DATA":/data \
    portainer/portainer-ce
else
  log "Portainer already running."
fi

# Prompt for Portainer connection info
cat <<EOF
============================
Portainer is running on port 9000.
Please connect via browser and set up your admin account.
============================
EOF
