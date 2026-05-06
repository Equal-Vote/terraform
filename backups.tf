# Backup instance for each tagged disk
resource "azurerm_data_protection_backup_instance_disk" "pvc" {
  for_each                     = var.disk_ids
  name                         = replace(basename(each.value), "kubernetes-dynamic-pvc-", "")
  vault_id                     = azurerm_data_protection_backup_vault.equalvote.id
  location                     = azurerm_resource_group.equalvote.location
  disk_id                      = each.value
  backup_policy_id             = azurerm_data_protection_backup_policy_disk.equalvote.id
  snapshot_resource_group_name = azurerm_kubernetes_cluster.equalvote.node_resource_group
}

resource "azurerm_data_protection_backup_vault" "equalvote" {
  name                = "equalvote-backup-vault"
  resource_group_name = azurerm_resource_group.equalvote.name
  location            = azurerm_resource_group.equalvote.location
  datastore_type      = "VaultStore"
  redundancy          = "LocallyRedundant"
}

resource "azurerm_data_protection_backup_policy_disk" "equalvote" {
  name     = "equalvote-backup-policy"
  vault_id = azurerm_data_protection_backup_vault.equalvote.id

  backup_repeating_time_intervals = ["R/2025-01-01T02:00:00+00:00/P1D"]
  default_retention_duration      = "P7D"

  retention_rule {
    name     = "Daily"
    duration = "P7D"
    priority = 25
    criteria {
      absolute_criteria = "FirstOfDay"
    }
  }

  retention_rule {
    name     = "Weekly"
    duration = "P28D"
    priority = 20
    criteria {
      absolute_criteria = "FirstOfWeek"
    }
  }

  retention_rule {
    name     = "Monthly"
    duration = "P180D"
    priority = 15
    criteria {
      absolute_criteria = "FirstOfMonth"
    }
  }
}
