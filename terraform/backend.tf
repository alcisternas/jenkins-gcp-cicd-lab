terraform {
  backend "gcs" {
    bucket = "my-project-bootstrap-476516-terraform-state"
    prefix = "jenkins-lab/infrastructure"
  }
}