# Based on https://techcommunity.microsoft.com/t5/azure-global/gitops-and-secret-management-with-aks-flux-cd-sops-and-azure-key/ba-p/2280068
# This is for the sops key that we use to encrypted all Kubernetes secrets.

# Updated provider in main.tf to use these features.
#provider "azurerm" {
#  features {
#    key_vault {
#      purge_soft_deleted_keys_on_destroy = true
#      recover_soft_deleted_keys          = true
#    }
#  }
#}

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "equalvote" {
  name                       = "equalvote"
  location                   = azurerm_resource_group.equalvote.location
  resource_group_name        = azurerm_resource_group.equalvote.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 7

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "Create",
      "Delete",
      "Get",
      "Purge",
      "Recover",
      "Update",
      "GetRotationPolicy",
      "SetRotationPolicy"
    ]

    secret_permissions = [
      "Set",
    ]
  }
}

resource "azurerm_key_vault_key" "sops" {
  name         = "sops"
  key_vault_id = azurerm_key_vault.equalvote.id
  key_type     = "RSA"
  key_opts = [
    "decrypt",
    "encrypt",
  ]
  rotation_policy {
    automatic {
      time_before_expiry = "P30D"
    }
    expire_after         = "P90D"
    notify_before_expiry = "P29D"
  }
}
