variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "network_name" {
  description = "VPC Network name"
  type        = string
}

variable "subnet_name" {
  description = "Subnet name"
  type        = string
}

variable "subnet_cidr" {
  description = "Subnet CIDR range"
  type        = string
}

variable "allowed_ssh_sources" {
  description = "List of CIDR ranges allowed for SSH access"
  type        = list(string)
}

variable "allowed_jenkins_sources" {
  description = "List of CIDR ranges allowed for Jenkins web access"
  type        = list(string)
}