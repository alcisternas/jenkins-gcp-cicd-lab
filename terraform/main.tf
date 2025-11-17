# Network Module
module "network" {
  source = "./network"

  project_id   = var.project_id
  region       = var.region
  environment  = var.environment
  network_name = var.network_name
  subnet_name  = var.subnet_name
  subnet_cidr  = var.subnet_cidr

  allowed_ssh_sources     = var.allowed_ssh_sources
  allowed_jenkins_sources = var.allowed_jenkins_sources
}

# Jenkins VM Module
module "jenkins_vm" {
  source = "./jenkins-vm"

  project_id            = var.project_id
  zone                  = var.zone
  environment           = var.environment
  vm_name               = var.vm_name
  vm_machine_type       = var.vm_machine_type
  vm_disk_size_gb       = var.vm_disk_size_gb
  vm_disk_type          = var.vm_disk_type
  service_account_email = var.service_account_email

  network_name = module.network.network_name
  subnet_name  = module.network.subnet_name
  network_tags = ["jenkins-server"]

  depends_on = [module.network]
}