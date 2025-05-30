terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }

    google = {
      source  = "hashicorp/google"
      version = "6.37.0"
    }

    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.31.0"
    }
  }
}

locals {
  cluster_issuer_url = "https://${local.cluster_issuer_uri}"
  cluster_issuer_uri = "container.googleapis.com/v1/projects/flux-gitops-playground/locations/us-central1/clusters/gds-hackathon"
}
