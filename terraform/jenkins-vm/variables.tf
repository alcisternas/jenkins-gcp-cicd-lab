variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "zone" {
  description = "GCP Zone"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vm_name" {
  description = "VM instance name"
  type        = string
}

variable "vm_machine_type" {
  description = "VM machine type"
  type        = string
}

variable "vm_disk_size_gb" {
  description = "Boot disk size in GB"
  type        = number
}

variable "vm_disk_type" {
  description = "Boot disk type"
  type        = string
}

variable "service_account_email" {
  description = "Service Account email to attach to VM"
  type        = string
}

variable "network_name" {
  description = "Network name"
  type        = string
}

variable "subnet_name" {
  description = "Subnet name"
  type        = string
}

variable "network_tags" {
  description = "Network tags for firewall rules"
  type        = list(string)
  default     = []
}