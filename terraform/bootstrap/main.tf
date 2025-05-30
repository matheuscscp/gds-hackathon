terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

locals {
  tf_cloud_issuer_host = "app.terraform.io"
  tf_cloud_issuer_url  = "https://${local.tf_cloud_issuer_host}"
  tf_cloud_audience    = "aws.workload.identity"
}

resource "aws_iam_openid_connect_provider" "terraform_cloud" {
  url = local.tf_cloud_issuer_url

  client_id_list = [local.tf_cloud_audience]
}

resource "aws_iam_role_policy_attachment" "terraform_cloud" {
  role       = aws_iam_role.terraform_cloud.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_role" "terraform_cloud" {
  name = "TerraformCloudRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.terraform_cloud.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${local.tf_cloud_issuer_host}:aud" = local.tf_cloud_audience
          }
          StringLike = {
            "${local.tf_cloud_issuer_host}:sub" = "organization:matheuscscp:project:default:workspace:gds-hackathon:run_phase:*"
          }
        }
      }
    ]
  })
}
