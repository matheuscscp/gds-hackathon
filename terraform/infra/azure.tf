provider "azurerm" {
  features {}
  subscription_id      = local.azure_subscription_id
  use_cli              = false
  use_oidc             = true
  client_id_file_path  = var.tfc_azure_dynamic_credentials.default.client_id_file_path
  oidc_token_file_path = var.tfc_azure_dynamic_credentials.default.oidc_token_file_path
  tenant_id            = "4bd9a3a0-4393-4c05-ab26-77f6c0bfc693"
}

locals {
  azure_subscription_id     = "db1051fa-ca70-4fed-a721-637b2621c974"
  azure_resource_group_name = "flux-tests"
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

resource "azurerm_container_registry" "artifact_registry" {
  location            = "East US"
  name                = "gdshackathon"
  resource_group_name = local.azure_resource_group_name
  sku                 = "Standard"
}

resource "azurerm_user_assigned_identity" "push_kubernetes" {
  name                = "push-kubernetes"
  location            = "East US"
  resource_group_name = local.azure_resource_group_name
}

resource "azurerm_federated_identity_credential" "push_kubernetes" {
  name                = "push-kubernetes"
  resource_group_name = local.azure_resource_group_name
  audience            = ["api://AzureADTokenExchange"]
  issuer              = "https://token.actions.githubusercontent.com"
  subject             = "repo:matheuscscp/gds-hackathon:ref:refs/heads/main"
  parent_id           = azurerm_user_assigned_identity.push_kubernetes.id
}

resource "azurerm_role_assignment" "push_kubernetes" {
  scope                = azurerm_container_registry.artifact_registry.id
  role_definition_name = "AcrPush"
  principal_id         = azurerm_user_assigned_identity.push_kubernetes.principal_id
}

resource "azurerm_user_assigned_identity" "pull_kubernetes" {
  name                = "pull-kubernetes"
  location            = "East US"
  resource_group_name = local.azure_resource_group_name
}

resource "azurerm_federated_identity_credential" "pull_kubernetes" {
  name                = "pull-kubernetes"
  resource_group_name = local.azure_resource_group_name
  audience            = ["api://AzureADTokenExchange"]
  issuer              = "https://container.googleapis.com/v1/projects/flux-gitops-playground/locations/us-central1/clusters/gds-hackathon"
  subject             = "system:serviceaccount:flux-system:flux-system-ocirepo"
  parent_id           = azurerm_user_assigned_identity.pull_kubernetes.id
}

resource "azurerm_role_assignment" "pull_kubernetes" {
  scope                = azurerm_container_registry.artifact_registry.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.pull_kubernetes.principal_id
}
