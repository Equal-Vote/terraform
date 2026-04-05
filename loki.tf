# Managed identity for Loki to access Azure Blob Storage via workload identity
resource "azurerm_user_assigned_identity" "loki-identity" {
  name                = "loki"
  resource_group_name = azurerm_resource_group.equalvote.name
  location            = azurerm_resource_group.equalvote.location
}

# Federated credential binding the Loki Kubernetes service account to the Azure managed identity
resource "azurerm_federated_identity_credential" "loki-federated-credential" {
  name      = "loki-federated-credential"
  parent_id = azurerm_user_assigned_identity.loki-identity.id
  issuer    = azurerm_kubernetes_cluster.equalvote.oidc_issuer_url
  subject   = "system:serviceaccount:loki:loki"
  audience  = ["api://AzureADTokenExchange"]
}

# Grant Loki read/write access to the storage account for log storage
resource "azurerm_role_assignment" "loki-storage-contributor" {
  scope                = azurerm_storage_account.storage.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.loki-identity.principal_id
}

output "loki_client_id" {
  description = "Client ID for the Loki managed identity. Set this in argocd/applications/loki/values.yaml under serviceAccount.annotations.azure.workload.identity/client-id"
  value       = azurerm_user_assigned_identity.loki-identity.client_id
}
