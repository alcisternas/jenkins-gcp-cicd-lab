# Jenkins Lab - Terraform Infrastructure

This directory contains Terraform code to provision the complete infrastructure for the Jenkins CI/CD laboratory on Google Cloud Platform.

## Architecture
```
jenkins-lab-infrastructure/
├── VPC Network (jenkins-lab-vpc)
│   ├── Subnet (jenkins-subnet - 10.10.0.0/24)
│   ├── Cloud Router
│   ├── Cloud NAT
│   └── Firewall Rules (SSH, Jenkins, Internal)
└── Compute Instance (jenkins-lab-vm)
    ├── Ubuntu 22.04 LTS
    ├── Service Account Attached
    ├── Podman Rootless
    └── Jenkins Container
```

## Prerequisites

- Terraform >= 1.5.0
- GCP Project with billing enabled
- Service Account with required permissions
- GCS bucket for Terraform state (already configured)

## Module Structure

### Network Module (`./network`)
- VPC Network (custom mode)
- Subnet with Private Google Access
- Cloud Router and Cloud NAT
- Firewall rules

### Jenkins VM Module (`./jenkins-vm`)
- Compute Engine instance
- Startup script for automated setup
- Podman rootless configuration
- Jenkins as systemd service

## Usage

### Initialize Terraform
```bash
cd terraform
terraform init
```

### Validate Configuration
```bash
terraform validate
```

### Plan Infrastructure
```bash
terraform plan
```

### Apply Infrastructure
```bash
terraform apply
```

### Destroy Infrastructure
```bash
terraform destroy
```

## Outputs

After `terraform apply`, you'll get:

- `jenkins_url`: Direct URL to access Jenkins
- `jenkins_vm_external_ip`: External IP of Jenkins VM
- `ssh_command`: Command to SSH into the VM
- `get_jenkins_password_command`: Command to retrieve initial admin password

## Configuration

Edit `terraform.tfvars` to customize:

- Project ID
- Region/Zone
- VM specifications
- Network CIDR ranges
- Allowed source IPs for SSH/Jenkins

## Security Notes

- Jenkins runs as non-root user (rootless Podman)
- Service Account attached to VM (no JSON keys)
- Private Google Access enabled
- Firewall rules restrict access
- Shielded VM enabled

## Troubleshooting

### Check Jenkins Status
```bash
gcloud compute ssh jenkins-lab-vm --command="jenkins-status"
```

### View Startup Script Logs
```bash
gcloud compute ssh jenkins-lab-vm --command="sudo cat /var/log/jenkins-setup.log"
```

### Get Jenkins Password
```bash
terraform output get_jenkins_password_command
# Then run the command shown
```

## Cost Estimate

- VM e2-standard-4: ~$98/month
- Disk 50GB SSD: ~$4/month
- Cloud NAT: ~$45/month base
- External IP (ephemeral): $0 (while VM running)
- **Total: ~$147/month**

## State Management

Terraform state is stored in:
- Bucket: `my-project-bootstrap-476516-terraform-state`
- Prefix: `jenkins-lab/infrastructure`

## Next Steps

After infrastructure is provisioned:
1. Access Jenkins UI at the provided URL
2. Retrieve initial admin password
3. Complete Jenkins setup wizard
4. Install required plugins
5. Configure Jenkins (Hito 2)