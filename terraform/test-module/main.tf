# Terraform Test Module for Jenkins Integration
# This module doesn't create any resources, just validates Terraform + GCP access

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# Provider configuration - uses Application Default Credentials
provider "google" {
  project = var.project_id
  region  = var.region
}

# Data source to verify GCP access
data "google_project" "current" {
  project_id = var.project_id
}

# Output to confirm access
output "project_info" {
  description = "Current GCP project information"
  value = {
    project_id     = data.google_project.current.project_id
    project_name   = data.google_project.current.name
    project_number = data.google_project.current.number
  }
}