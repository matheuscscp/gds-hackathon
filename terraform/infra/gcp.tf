provider "google" {
  project = local.gcp_project
  region  = "us-central1"
}

locals {
  gcp_project        = "flux-gitops-playground"
  gcp_project_number = "234382750829"
}

resource "google_container_cluster" "main" {
  name                = "gds-hackathon"
  enable_autopilot    = true
  project             = local.gcp_project
  deletion_protection = false
}
