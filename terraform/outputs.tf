output "network_name" {
  description = "Name of the VPC network"
  value       = module.network.network_name
}

output "subnet_name" {
  description = "Name of the subnet"
  value       = module.network.subnet_name
}

output "subnet_cidr" {
  description = "CIDR range of the subnet"
  value       = module.network.subnet_cidr
}

output "jenkins_vm_name" {
  description = "Name of Jenkins VM"
  value       = module.jenkins_vm.vm_name
}

output "jenkins_vm_internal_ip" {
  description = "Internal IP of Jenkins VM"
  value       = module.jenkins_vm.vm_internal_ip
}

output "jenkins_vm_external_ip" {
  description = "External IP of Jenkins VM"
  value       = module.jenkins_vm.vm_external_ip
}

output "jenkins_url" {
  description = "Jenkins web interface URL"
  value       = "http://${module.jenkins_vm.vm_external_ip}:8080"
}

output "ssh_command" {
  description = "Command to SSH into Jenkins VM"
  value       = "gcloud compute ssh ${module.jenkins_vm.vm_name} --project=${var.project_id} --zone=${var.zone}"
}

output "get_jenkins_password_command" {
  description = "Command to get Jenkins initial admin password"
  value       = "gcloud compute ssh ${module.jenkins_vm.vm_name} --project=${var.project_id} --zone=${var.zone} --command='sudo su - jenkins -c \"podman exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword\"'"
}