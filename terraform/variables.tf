variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "GCP Zone"
  type        = string
  default     = "us-central1-a"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "lab"
}

variable "service_account_email" {
  description = "Service Account email for Jenkins VM"
  type        = string
}

variable "network_name" {
  description = "VPC Network name"
  type        = string
  default     = "jenkins-lab-vpc"
}

variable "subnet_name" {
  description = "Subnet name"
  type        = string
  default     = "jenkins-subnet"
}

variable "subnet_cidr" {
  description = "Subnet CIDR range"
  type        = string
  default     = "10.10.0.0/24"
}

variable "vm_name" {
  description = "Jenkins VM name"
  type        = string
  default     = "jenkins-lab-vm"
}

variable "vm_machine_type" {
  description = "Jenkins VM machine type"
  type        = string
  default     = "e2-standard-4"
}

variable "vm_disk_size_gb" {
  description = "Jenkins VM boot disk size in GB"
  type        = number
  default     = 50
}

variable "vm_disk_type" {
  description = "Jenkins VM boot disk type"
  type        = string
  default     = "pd-balanced"
}

variable "allowed_ssh_sources" {
  description = "List of CIDR ranges allowed for SSH access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "allowed_jenkins_sources" {
  description = "List of CIDR ranges allowed for Jenkins web access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}