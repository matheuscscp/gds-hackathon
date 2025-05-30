provider "aws" {
  region = "us-east-1"
}

locals {
  aws_audience    = "sts.amazonaws.com"
  aws_bucket_name = "gds-hackathon-object-store"
}

resource "aws_s3_bucket" "object_store" {
  bucket = "gds-hackathon-object-store"
}

resource "aws_s3_bucket_public_access_block" "object_store" {
  bucket = local.aws_bucket_name

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_iam_openid_connect_provider" "gke_main" {
  url = local.cluster_issuer_url

  client_id_list = [local.aws_audience]
}

resource "aws_s3_bucket_policy" "app" {
  bucket = local.aws_bucket_name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.app.arn
        }
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket",
        ]
        Resource = [
          "${aws_s3_bucket.object_store.arn}/*",
          aws_s3_bucket.object_store.arn
        ]
      }
    ]
  })
}

resource "aws_iam_role" "app" {
  name = "AppRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.gke_main.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${local.cluster_issuer_uri}:aud" = local.aws_audience
          }
          StringLike = {
            "${local.cluster_issuer_uri}:sub" = "system:serviceaccount:default:app"
          }
        }
      }
    ]
  })
}
