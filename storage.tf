
resource "azurerm_storage_account" "storage" {
  name                     = "defaultstorageacct"
  resource_group_name      = azurerm_resource_group.equalvote.name
  location                 = azurerm_resource_group.equalvote.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  access_tier              = "Hot"
  is_hns_enabled           = false
}

resource "azurerm_storage_container" "blobs" {
  name                 = "candidate-photos"
  storage_account_id   = azurerm_storage_account.storage.id
  container_access_type = "blob"
}

