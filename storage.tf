resource "azurerm_resource_group" "storage_rg" {
  name     = "rg-default-storage"
  location = "eastus"
}

resource "azurerm_storage_account" "storage" {
  name                     = "stdefaultstorageacct"
  resource_group_name      = azurerm_resource_group.storage_rg.name
  location                 = azurerm_resource_group.storage_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  allow_blob_public_access = false
  is_hns_enabled           = false
}

resource "azurerm_storage_container" "blobs" {
  name                  = "default-container"
  storage_account_name  = azurerm_storage_account.storage.name
  container_access_type = "private"
}

output "storage_account_name" {
  value = azurerm_storage_account.storage.name
}

output "storage_container_name" {
  value = azurerm_storage_container.blobs.name
}

output "storage_resource_group" {
  value = azurerm_resource_group.storage_rg.name
}
