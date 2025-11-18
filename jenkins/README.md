# Jenkins Custom Docker Image

Custom Jenkins LTS image with pre-installed plugins and Configuration as Code for GCP CI/CD Lab.

## Files

- `Dockerfile` - Custom Jenkins image definition
- `plugins.txt` - List of plugins to pre-install
- `jenkins-casc.yaml` - Configuration as Code (JCasC) setup
- `Jenkinsfile` - Pipeline definitions (for Hito 7+)

## Features

- Jenkins LTS with JDK 17
- Pre-installed plugins for GCP, Docker, Terraform, Git
- Configuration as Code (JCasC) enabled
- Git pre-installed in image
- Setup wizard disabled
- Automated security configuration with admin user

## Build Image
```bash
# Local build (requires Docker Desktop)
docker build -t jenkins-custom:1.0.0 .
```

## Test Locally
```bash
docker run -d \
  --name jenkins-test \
  -p 8080:8080 \
  -p 50000:50000 \
  -e JENKINS_ADMIN_ID=jenks \
  -e JENKINS_ADMIN_PASSWORD=admin123 \
  jenkins-custom:1.0.0

# Access: http://localhost:8080
# Login: jenks / admin123
```

## Push to GCP Artifact Registry
```bash
# Authenticate
gcloud auth configure-docker us-central1-docker.pkg.dev

# Tag for Artifact Registry
docker tag jenkins-custom:1.0.0 \
  us-central1-docker.pkg.dev/possible-sun-471215-d3/apps/jenkins-custom:1.0.0

docker tag jenkins-custom:1.0.0 \
  us-central1-docker.pkg.dev/possible-sun-471215-d3/apps/jenkins-custom:latest

# Push
docker push us-central1-docker.pkg.dev/possible-sun-471215-d3/apps/jenkins-custom:1.0.0
docker push us-central1-docker.pkg.dev/possible-sun-471215-d3/apps/jenkins-custom:latest
```

## Environment Variables

- `JENKINS_ADMIN_ID` - Admin username (required)
- `JENKINS_ADMIN_PASSWORD` - Admin password (required)
- `JENKINS_URL` - Jenkins URL for configuration (optional)

## Usage in Terraform

The custom image is pulled from Artifact Registry in the VM startup script:
```bash
podman pull us-central1-docker.pkg.dev/possible-sun-471215-d3/apps/jenkins-custom:latest
podman run -d --name jenkins \
  -p 8080:8080 -p 50000:50000 \
  -v /home/jenkins/jenkins_home:/var/jenkins_home \
  -e JENKINS_ADMIN_ID=jenks \
  -e JENKINS_ADMIN_PASSWORD=admin123 \
  -e JENKINS_URL=http://VM_IP:8080 \
  us-central1-docker.pkg.dev/possible-sun-471215-d3/apps/jenkins-custom:latest
```