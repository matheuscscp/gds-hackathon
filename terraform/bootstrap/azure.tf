provider "azurerm" {
  features {}
  subscription_id = local.azure_subscription_id
}

locals {
  azure_subscription_id     = "db1051fa-ca70-4fed-a721-637b2621c974"
  azure_resource_group_name = "flux-tests"
}

resource "azurerm_user_assigned_identity" "terraform_cloud" {
  name                = "terraform-cloud"
  location            = "East US"
  resource_group_name = local.azure_resource_group_name
}

resource "azurerm_federated_identity_credential" "terraform_cloud_plan" {
  name                = "terraform-cloud-plan"
  resource_group_name = local.azure_resource_group_name
  audience            = ["api://AzureADTokenExchange"]
  issuer              = local.tf_cloud_issuer_url
  subject             = "${local.tf_cloud_subject_prefix}plan"
  parent_id           = azurerm_user_assigned_identity.terraform_cloud.id
}

resource "azurerm_federated_identity_credential" "terraform_cloud_apply" {
  name                = "terraform-cloud-apply"
  resource_group_name = local.azure_resource_group_name
  audience            = ["api://AzureADTokenExchange"]
  issuer              = local.tf_cloud_issuer_url
  subject             = "${local.tf_cloud_subject_prefix}apply"
  parent_id           = azurerm_user_assigned_identity.terraform_cloud.id
}

resource "azurerm_role_assignment" "terraform_cloud" {
  scope                = "/subscriptions/${local.azure_subscription_id}"
  role_definition_name = "Owner"
  principal_id         = azurerm_user_assigned_identity.terraform_cloud.principal_id
}
