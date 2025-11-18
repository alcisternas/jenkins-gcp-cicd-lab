FROM jenkins/jenkins:lts-jdk17

# Metadata
LABEL maintainer="alejandro.cisternas@gmail.com"
LABEL description="Custom Jenkins image with JCasC for GCP CI/CD Lab"
LABEL version="1.1.0"

# Switch to root to install system packages
USER root

# Install Git and other system tools
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    git \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install Google Cloud SDK (gcloud CLI)
RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | \
    tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && \
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | \
    apt-key --keyring /usr/share/keyrings/cloud.google.gpg add - && \
    apt-get update && \
    apt-get install -y google-cloud-cli && \
    rm -rf /var/lib/apt/lists/*

# Switch back to jenkins user
USER jenkins

# Disable Jenkins setup wizard
ENV JAVA_OPTS="-Djenkins.install.runSetupWizard=false"

# Set JCasC configuration path
ENV CASC_JENKINS_CONFIG=/var/jenkins_home/casc_configs/jenkins.yaml

# Copy plugins list
COPY --chown=jenkins:jenkins plugins.txt /usr/share/jenkins/ref/plugins.txt

# Install plugins from plugins.txt
RUN jenkins-plugin-cli --plugin-file /usr/share/jenkins/ref/plugins.txt

# Copy JCasC configuration
COPY --chown=jenkins:jenkins jenkins-casc.yaml /usr/share/jenkins/ref/casc_configs/jenkins.yaml

# Expose ports
EXPOSE 8080 50000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=90s --retries=3 \
  CMD curl -f http://localhost:8080/login || exit 1