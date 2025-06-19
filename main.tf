# Based on:
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_cluster

terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
    }
  }
  backend "azurerm" {
    resource_group_name  = "tfstate"
    storage_account_name = "equalvoteterraform"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_deleted_keys_on_destroy = true
      recover_soft_deleted_keys          = true
    }
  }
}

resource "azurerm_resource_group" "equalvote" {
  name     = "equalvote"
  location = "West US 2"
}

resource "azurerm_kubernetes_cluster" "equalvote" {
  location            = azurerm_resource_group.equalvote.location
  name                = "equalvote"
  resource_group_name = azurerm_resource_group.equalvote.name
  dns_prefix          = "equalvote"

  # You can get available versions with this command:
  # az aks get-upgrades --resource-group equalvote --name equalvote --output table
  kubernetes_version  = "1.29.15"

  # Enabling OIDC and Workload Identity so external-dns and cert-manager can manage DNS records in Azure DNS.
  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  identity {
    type = "SystemAssigned"
  }

  default_node_pool {
    name       = "agentpool"
    vm_size    = "Standard_B2as_v2"
    node_count = var.node_count

    # This "optional" setting is needed if you ever want to actually change one
    # of like 15 other settings in your cluster. More Azure nonsense - just
    # create a new node pool with timestamp to make it unique or something. WTF
    # Azure!
    temporary_name_for_rotation = "wtfazure"

  }

}

resource "azurerm_virtual_network" "equalvote" {
  name                = "equalvote"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.equalvote.location
  resource_group_name = azurerm_resource_group.equalvote.name
}

resource "azurerm_subnet" "equalvote" {
  name                 = "equalvote"
  resource_group_name  = "equalvote"
  virtual_network_name = azurerm_virtual_network.equalvote.name
  address_prefixes     = ["10.0.1.0/24"]
  service_endpoints    = ["Microsoft.Storage"]
}

# Ran:
# terraform import azurerm_dns_zone.sandbox /subscriptions/86f3145a-48cc-4255-8757-dd3104d15e57/resourceGroups/equalvote/providers/Microsoft.Network/dnszones/sandbox.star.vote
# but it failed. I copied the id directly from the Azure portal, but lo and behold, you have to have a capital "Z" like this to make it work:
# terraform import azurerm_dns_zone.sandbox /subscriptions/86f3145a-48cc-4255-8757-dd3104d15e57/resourceGroups/equalvote/providers/Microsoft.Network/dnsZones/sandbox.star.vote
resource "azurerm_dns_zone" "sandbox" {
  name                = "sandbox.star.vote"
  resource_group_name = azurerm_resource_group.equalvote.name
}
resource "azurerm_dns_zone" "prod" {
  name                = "prod.equal.vote"
  resource_group_name = azurerm_resource_group.equalvote.name
}
resource "azurerm_dns_zone" "dev" {
  name                = "dev.equal.vote"
  resource_group_name = azurerm_resource_group.equalvote.name
}
