# Get latest Ubuntu 22.04 LTS image
data "google_compute_image" "ubuntu" {
  family  = "ubuntu-2204-lts"
  project = "ubuntu-os-cloud"
}

# Jenkins VM Instance
resource "google_compute_instance" "jenkins_vm" {
  name         = var.vm_name
  machine_type = var.vm_machine_type
  zone         = var.zone
  project      = var.project_id

  tags = var.network_tags

  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu.self_link
      size  = var.vm_disk_size_gb
      type  = var.vm_disk_type
    }
    auto_delete = true
  }

  network_interface {
    network    = var.network_name
    subnetwork = var.subnet_name

    access_config {
      # Ephemeral external IP
    }
  }

  service_account {
    email  = var.service_account_email
    scopes = ["cloud-platform"]
  }

  metadata = {
  enable-oslogin   = "TRUE"
  startup-script = file("${path.module}/startup-script.sh")
}

  shielded_instance_config {
    enable_secure_boot          = false
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }

  labels = {
    environment = var.environment
    purpose     = "jenkins-cicd"
    managed_by  = "terraform"
  }
}