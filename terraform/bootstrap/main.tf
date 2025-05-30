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
  tf_cloud_issuer_host    = "app.terraform.io"
  tf_cloud_issuer_url     = "https://${local.tf_cloud_issuer_host}"
  tf_cloud_subject_prefix = "organization:matheuscscp:project:default:workspace:gds-hackathon:run_phase:"
  tf_cloud_aws_audience   = "aws.workload.identity"
}
