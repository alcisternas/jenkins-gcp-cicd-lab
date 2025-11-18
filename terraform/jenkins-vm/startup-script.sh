 #!/bin/bash
set -e

# Variables
JENKINS_USER="jenkins"
JENKINS_HOME="/home/${JENKINS_USER}/jenkins_home"
LOG_FILE="/var/log/jenkins-setup.log"
JENKINS_IMAGE="us-central1-docker.pkg.dev/possible-sun-471215-d3/apps/jenkins-custom:latest"

# Redirect output to log file
exec > >(tee -a ${LOG_FILE})
exec 2>&1

echo "=== Jenkins VM Setup Started at $(date) ==="

# 1. Update system
echo "[$(date)] Updating system packages..."
DEBIAN_FRONTEND=noninteractive apt-get update
DEBIAN_FRONTEND=noninteractive apt-get upgrade -y

# 2. Install Podman and dependencies
echo "[$(date)] Installing Podman and dependencies..."
apt-get install -y podman uidmap slirp4netns fuse-overlayfs

# 3. Create Jenkins user (non-root)
echo "[$(date)] Creating Jenkins user..."
if ! id "${JENKINS_USER}" &>/dev/null; then
    useradd -m -s /bin/bash ${JENKINS_USER}
    echo "${JENKINS_USER}:$(openssl rand -base64 32)" | chpasswd
fi

# 4. Enable lingering for jenkins user (keeps user services running)
echo "[$(date)] Enabling lingering for Jenkins user..."
loginctl enable-linger ${JENKINS_USER}

# 5. Configure subuid and subgid for rootless Podman
echo "[$(date)] Configuring subuid and subgid..."
if ! grep -q "^${JENKINS_USER}:" /etc/subuid; then
    echo "${JENKINS_USER}:100000:65536" >> /etc/subuid
fi
if ! grep -q "^${JENKINS_USER}:" /etc/subgid; then
    echo "${JENKINS_USER}:100000:65536" >> /etc/subgid
fi

# 6. Create Jenkins home directory
echo "[$(date)] Creating Jenkins home directory..."
mkdir -p ${JENKINS_HOME}
chown -R ${JENKINS_USER}:${JENKINS_USER} ${JENKINS_HOME}
chmod -R 777 ${JENKINS_HOME}

# 7. Configure Podman storage for rootless
echo "[$(date)] Configuring Podman storage..."
mkdir -p /home/${JENKINS_USER}/.config/containers
cat > /home/${JENKINS_USER}/.config/containers/storage.conf <<EOF
[storage]
driver = "overlay"
runroot = "/run/user/1001/containers"
graphroot = "/home/${JENKINS_USER}/.local/share/containers/storage"

[storage.options]
mount_program = "/usr/bin/fuse-overlayfs"
EOF

chown -R ${JENKINS_USER}:${JENKINS_USER} /home/${JENKINS_USER}/.config

# 8. Pull Jenkins custom image from Artifact Registry
echo "[$(date)] Pulling Jenkins custom image from Artifact Registry..."
su - ${JENKINS_USER} -c "podman pull ${JENKINS_IMAGE}"

# 9. Create systemd service for Jenkins
echo "[$(date)] Creating systemd service..."
mkdir -p /home/${JENKINS_USER}/.config/systemd/user
cat > /home/${JENKINS_USER}/.config/systemd/user/jenkins.service <<EOF
[Unit]
Description=Jenkins CI/CD Server (Rootless Podman - Custom Image)
After=network-online.target
Wants=network-online.target

[Service]
Restart=always
TimeoutStartSec=0
ExecStartPre=-/usr/bin/podman stop jenkins
ExecStartPre=-/usr/bin/podman rm jenkins
ExecStart=/usr/bin/podman run --name jenkins \\
  -p 8080:8080 \\
  -p 50000:50000 \\
  -v ${JENKINS_HOME}:/var/jenkins_home \\
  -e JENKINS_ADMIN_ID=jenks \\
  -e JENKINS_ADMIN_PASSWORD=admin123 \\
  -e JENKINS_URL=http://\$(curl -s http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip -H "Metadata-Flavor: Google"):8080 \\
  ${JENKINS_IMAGE}
ExecStop=/usr/bin/podman stop jenkins

[Install]
WantedBy=default.target
EOF

chown -R ${JENKINS_USER}:${JENKINS_USER} /home/${JENKINS_USER}/.config/systemd

# 10. Enable and start Jenkins service
echo "[$(date)] Enabling and starting Jenkins service..."
su - ${JENKINS_USER} -c "XDG_RUNTIME_DIR=/run/user/1001 systemctl --user daemon-reload"
su - ${JENKINS_USER} -c "XDG_RUNTIME_DIR=/run/user/1001 systemctl --user enable jenkins.service"
su - ${JENKINS_USER} -c "XDG_RUNTIME_DIR=/run/user/1001 systemctl --user start jenkins.service"

# 11. Verify service status
echo "[$(date)] Checking Jenkins service status..."
su - ${JENKINS_USER} -c "XDG_RUNTIME_DIR=/run/user/1001 systemctl --user status jenkins.service --no-pager" || true

echo "=== Jenkins VM Setup Completed at $(date) ==="
echo "Jenkins will be available at http://\$(curl -s http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip -H 'Metadata-Flavor: Google'):8080"
echo "Login: jenks / admin123"