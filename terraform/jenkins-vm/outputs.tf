output "vm_name" {
  description = "Name of the VM instance"
  value       = google_compute_instance.jenkins_vm.name
}

output "vm_id" {
  description = "ID of the VM instance"
  value       = google_compute_instance.jenkins_vm.id
}

output "vm_internal_ip" {
  description = "Internal IP address of the VM"
  value       = google_compute_instance.jenkins_vm.network_interface[0].network_ip
}

output "vm_external_ip" {
  description = "External IP address of the VM"
  value       = google_compute_instance.jenkins_vm.network_interface[0].access_config[0].nat_ip
}

output "vm_self_link" {
  description = "Self link of the VM instance"
  value       = google_compute_instance.jenkins_vm.self_link
}