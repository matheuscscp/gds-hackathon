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

provider "aws" {
  region = "us-east-1"
}

provider "google" {
  project = local.gcp_project
  region  = "us-central1"
}

locals {
  gcp_project        = "flux-gitops-playground"
  gcp_project_number = "234382750829"
}

resource "aws_s3_bucket" "object_store" {
  bucket = "gds-hackathon-object-store"
}

resource "aws_s3_bucket_public_access_block" "object_store" {
  bucket = aws_s3_bucket.object_store.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "google_container_cluster" "main" {
  name             = "gds-hackathon"
  enable_autopilot = true
  project          = local.gcp_project
}
