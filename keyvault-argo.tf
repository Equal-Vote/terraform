# This is imported in the imports.tf file in this same directory
resource "azurerm_key_vault" "equalvote-argocd" {
  name                = "equalvote-argocd"
  location            = azurerm_resource_group.equalvote.location
  sku_name            = "standard"
  tenant_id           = data.azurerm_client_config.current.tenant_id
  resource_group_name = azurerm_resource_group.equalvote.name
}

# This is the identity that is created by the script
# Imported in the imports.tf file
resource "azurerm_user_assigned_identity" "argocd-identity" {
  name                = "argocd"
  resource_group_name = azurerm_resource_group.equalvote.name
  location            = azurerm_resource_group.equalvote.location
}

# Imported in the Terraform imports
resource "azurerm_key_vault_key" "sops-key" {
  name         = "sops-key"
  key_vault_id = azurerm_key_vault.equalvote-argocd.id
  key_type     = "RSA"
  key_size     = 2048

  key_opts = [
    "encrypt",
    "decrypt",
  ]

}

# This resource encapsulates the 'az keyvault set-policy' command in your script
# Recreating this policy as Arturo has instructed that he will delete the existent one
resource "azurerm_key_vault_access_policy" "argocd-policy" {
  key_vault_id = azurerm_key_vault.equalvote-argocd.id

  tenant_id = azurerm_user_assigned_identity.argocd-identity.tenant_id

  # This is is the object id in azure's terraform nomenclature
  # Reference: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/user_assigned_identity#principal_id
  object_id = azurerm_user_assigned_identity.argocd-identity.principal_id

  # Did not see an option to set all permissions so I had to type them all out from here:
  # https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_access_policy#key_permissions
  key_permissions = [
    "Backup",
    "Create",
    "Decrypt",
    "Delete",
    "Encrypt",
    "Get",
    "Import",
    "List",
    "Purge",
    "Recover",
    "Restore",
    "Sign",
    "UnwrapKey",
    "Update",
    "Verify",
    "WrapKey",
    "Release",
    "Rotate",
    "GetRotationPolicy",
    "SetRotationPolicy"
  ]

  depends_on = [
    azurerm_key_vault.equalvote-argocd,
    azurerm_user_assigned_identity.argocd-identity
  ]
}

# Super unsure about this one because I am getting it from the generalized docs on terraform and not Azure
# https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service_account.html
resource "kubernetes_service_account" "aks-argocd" {
  metadata {
    name      = "aks-argocd"
    namespace = "argocd"

    annotations = {
      "azure.workload.identity/client-id" = azurerm_user_assigned_identity.argocd-identity.client_id
      "azure.workload.identity/tenant-id" = azurerm_user_assigned_identity.argocd-identity.tenant_id
    }

    labels = {
      "azure.workload.identity/use" = "true"
    }
  }
}

# Worked through this with Arturo at the tueaday live session.
# Adds in the federated credential that was last created in Arturos script.
# Not going to import this one as well.
resource "azurerm_federated_identity_credential" "kubernetes-federated-credential" {
  name                = "kubernetes-federated-credential"
  resource_group_name = azurerm_resource_group.equalvote.name
  subject             = "system:serviceaccount:argocd:aks-argocd"

  depends_on = [
    azurerm_key_vault.equalvote-argocd,
    azurerm_user_assigned_identity.argocd-identity
  ]

  # Found this example that says we should be mapping to the ID and not principal_id
  parent_id = azurerm_user_assigned_identity.argocd-identity.id

  # Found this through the docuumentation here:
  # https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_cluster#oidc_issuer_url
  issuer = azurerm_kubernetes_cluster.equalvote.oidc_issuer_url

  # Found this wit Arturo through the CLI
  audience = ["api://AzureADTokenExchange"]

}
