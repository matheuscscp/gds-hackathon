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

provider "azurerm" {
  features {}
  subscription_id      = local.azure_subscription_id
  use_cli              = false
  use_oidc             = true
  client_id_file_path  = var.tfc_azure_dynamic_credentials.default.client_id_file_path
  oidc_token_file_path = var.tfc_azure_dynamic_credentials.default.oidc_token_file_path
  tenant_id            = "4bd9a3a0-4393-4c05-ab26-77f6c0bfc693"
}

variable "tfc_azure_dynamic_credentials" {
  description = "Object containing Azure dynamic credentials configuration"
  type = object({
    default = object({
      client_id_file_path  = string
      oidc_token_file_path = string
    })
    aliases = map(object({
      client_id_file_path  = string
      oidc_token_file_path = string
    }))
  })
}

locals {
  azure_subscription_id     = "db1051fa-ca70-4fed-a721-637b2621c974"
  azure_resource_group_name = "flux-tests"
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

resource "azurerm_container_registry" "artifact_registry" {
  location            = "East US"
  name                = "gdshackathon"
  resource_group_name = local.azure_resource_group_name
  sku                 = "Standard"
}
