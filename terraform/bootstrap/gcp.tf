provider "google" {
  project = local.gcp_project
  region  = "us-central1"
}

locals {
  gcp_project        = "flux-gitops-playground"
  gcp_project_number = "234382750829"
}

resource "google_iam_workload_identity_pool" "terraform_cloud" {
  workload_identity_pool_id = "terraform-cloud"
}

resource "google_iam_workload_identity_pool_provider" "terraform_cloud" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.terraform_cloud.workload_identity_pool_id
  workload_identity_pool_provider_id = "terraform-cloud"

  oidc {
    issuer_uri = local.tf_cloud_issuer_url
  }

  attribute_mapping = {
    "google.subject" = "assertion.sub"
  }

  attribute_condition = "assertion.terraform_organization_name == 'matheuscscp' && assertion.terraform_project_name == 'default' && assertion.terraform_workspace_name == 'gds-hackathon' && assertion.terraform_run_phase in ['plan', 'apply']"
}

resource "google_service_account" "terraform_cloud" {
  account_id = "terraform-cloud"
}

resource "google_project_iam_member" "terraform_cloud" {
  project = local.gcp_project
  role    = "roles/owner"
  member  = "serviceAccount:${google_service_account.terraform_cloud.email}"
}

resource "google_service_account_iam_binding" "terraform_cloud" {
  depends_on = [google_iam_workload_identity_pool.terraform_cloud]

  service_account_id = google_service_account.terraform_cloud.name
  role               = "roles/iam.workloadIdentityUser"
  members = [
    "principal://iam.googleapis.com/projects/${local.gcp_project_number}/locations/global/workloadIdentityPools/terraform-cloud/subject/${local.tf_cloud_subject_prefix}plan",
    "principal://iam.googleapis.com/projects/${local.gcp_project_number}/locations/global/workloadIdentityPools/terraform-cloud/subject/${local.tf_cloud_subject_prefix}apply",
  ]
}

output "workload_identity_pool_provider_audience" {
  value = "https://iam.googleapis.com/projects/${local.gcp_project_number}/locations/global/workloadIdentityPools/terraform-cloud/providers/terraform-cloud"
}
