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

# This resource encapsulates the 'az keyvault set-policy' command in your script
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
resource "kubernetes_service_account" "aks_argocd" {
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


## This is the last resource that I need to create below, but it is a little more involved than the previous stuff I made.
## Uncomment it to better see what I have so far.
## I only left it commented out because it causes terraform plan to brick if I leave it uncommented out.


# resource "azurerm_federated_identity_credential" "kubernetes-federated-credential" {
#   name                = "kubernetes-federated-credential"
#   resource_group_name = azurerm_resource_group.equalvote.name
#   subject             = "system:serviceaccount:argocd:aks-argocd"

#   depends_on = [
#     azurerm_key_vault.equalvote-argocd,
#     azurerm_user_assigned_identity.argocd-identity
#   ]


#   # This part could be wrong. The docs specifically say parent ID
#   # https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/federated_identity_credential#parent_id
#   # However, based off what I saw in the command, I assume that we are attaching the ID of the policy when creating this fed cred resource
#   parent_id = azurerm_user_assigned_identity.argocd-identity.principal_id

#   # I still have to figure out how to translate the query in the script to ghet the clusters issuerURL
#   issuer = ""

#   # I do not know what this is, but it is late so I will look more into it tomorrow
#   audience = ""

# }
