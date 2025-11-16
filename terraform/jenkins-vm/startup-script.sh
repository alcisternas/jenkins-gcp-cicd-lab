#!/bin/bash
set -e

# Variables
JENKINS_USER="jenkins"
JENKINS_HOME="/home/${JENKINS_USER}/jenkins_home"
LOG_FILE="/var/log/jenkins-setup.log"

# Redirect output to log file
exec > >(tee -a ${LOG_FILE})
exec 2>&1

echo "=== Jenkins VM Setup Started at $(date) ==="

# 1. Update system
echo "[$(date)] Updating system packages..."
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get upgrade -y

# 2. Install Podman and dependencies
echo "[$(date)] Installing Podman and dependencies..."
apt-get install -y podman uidmap slirp4netns fuse-overlayfs

# 3. Create Jenkins user (non-root)
echo "[$(date)] Creating Jenkins user..."
if ! id "${JENKINS_USER}" &>/dev/null; then
    useradd -m -s /bin/bash ${JENKINS_USER}
fi

# 4. Enable lingering for Jenkins user
echo "[$(date)] Enabling lingering for Jenkins user..."
loginctl enable-linger ${JENKINS_USER}

# 5. Configure subuid and subgid for rootless containers
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

# 7. Configure Podman storage for rootless
echo "[$(date)] Configuring Podman storage..."
mkdir -p /home/${JENKINS_USER}/.config/containers
cat > /home/${JENKINS_USER}/.config/containers/storage.conf <<EOF
[storage]
driver = "overlay"
runroot = "/run/user/$(id -u ${JENKINS_USER})/containers"
graphroot = "/home/${JENKINS_USER}/.local/share/containers/storage"

[storage.options]
pull_options = {enable_partial_images = "true", use_hard_links = "false", ostree_repos=""}

[storage.options.overlay]
mountopt = "nodev"
EOF

chown -R ${JENKINS_USER}:${JENKINS_USER} /home/${JENKINS_USER}/.config

# 8. Pull Jenkins image as jenkins user
echo "[$(date)] Pulling Jenkins LTS image..."
su - ${JENKINS_USER} -c "podman pull docker.io/jenkins/jenkins:lts"

# 9. Create systemd service for Jenkins
echo "[$(date)] Creating systemd service..."
mkdir -p /home/${JENKINS_USER}/.config/systemd/user
cat > /home/${JENKINS_USER}/.config/systemd/user/jenkins.service <<EOF
[Unit]
Description=Jenkins CI/CD Server (Rootless Podman)
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
  -v ${JENKINS_HOME}:/var/jenkins_home:Z \\
  docker.io/jenkins/jenkins:lts
ExecStop=/usr/bin/podman stop jenkins

[Install]
WantedBy=default.target
EOF

chown -R ${JENKINS_USER}:${JENKINS_USER} /home/${JENKINS_USER}/.config/systemd

# 10. Enable and start Jenkins service
echo "[$(date)] Enabling and starting Jenkins service..."
su - ${JENKINS_USER} -c "systemctl --user daemon-reload"
su - ${JENKINS_USER} -c "systemctl --user enable jenkins.service"
su - ${JENKINS_USER} -c "systemctl --user start jenkins.service"

# 11. Create helper script
echo "[$(date)] Creating helper scripts..."
cat > /usr/local/bin/get-jenkins-password <<'SCRIPT'
#!/bin/bash
su - jenkins -c "podman exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword"
SCRIPT

chmod +x /usr/local/bin/get-jenkins-password

cat > /usr/local/bin/jenkins-status <<'SCRIPT'
#!/bin/bash
echo "=== Jenkins Service Status ==="
su - jenkins -c "systemctl --user status jenkins.service"
echo ""
echo "=== Podman Container Status ==="
su - jenkins -c "podman ps -a | grep jenkins"
SCRIPT

chmod +x /usr/local/bin/jenkins-status

# 12. Wait for Jenkins to be ready
echo "[$(date)] Waiting for Jenkins to start (this may take 2-3 minutes)..."
sleep 120

# 13. Display completion info
echo "=== Jenkins VM Setup Completed at $(date) ==="
echo ""
echo "Jenkins is running in rootless Podman container"
echo "User: jenkins (UID: $(id -u ${JENKINS_USER}))"
echo "Jenkins Home: ${JENKINS_HOME}"
echo ""
echo "Useful commands:"
echo "  - Get initial admin password: get-jenkins-password"
echo "  - Check Jenkins status: jenkins-status"
echo "  - View logs: journalctl --user -u jenkins.service -f (as jenkins user)"
echo ""
echo "Access Jenkins at: http://$(curl -s ifconfig.me):8080"