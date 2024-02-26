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
  oidc_issuer_enabled = true
  workload_identity_enabled = true

  identity {
    type = "SystemAssigned"
  }

  default_node_pool {
    name       = "agentpool"
    vm_size    = "Standard_B2as_v2"
    node_count = var.node_count
  }

  network_profile {
    network_plugin    = "kubenet"
    load_balancer_sku = "standard"
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
