resource "azurerm_kubernetes_cluster" "k8s" {
  location            = azurerm_resource_group.star-server.location
  name                = "star-voting-cluster"
  resource_group_name = azurerm_resource_group.star-server.name
  dns_prefix          = "starvoting"

  default_node_pool {
    name                = "sv"
    availability_zones  = ["2"]
    vm_size             = "Standard_B2s"
    vnet_subnet_id      = azurerm_subnet.this.id
    node_count          = 2
    min_count           = 2
    max_count           = 2
  }

  service_principal {
    client_id = var.subscription_client_id
    client_secret = var.subscription_secret
  }

  default_node_pool {
    name       = "agentpool"
    vm_size    = "Standard_D2_v2"
    node_count = var.node_count
  }

  network_profile {
    network_plugin    = "kubenet"
    load_balancer_sku = "standard"
  }
}

resource "azurerm_virtual_network" "this" {
  name                = "sv-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.star-server.location
  resource_group_name = azurerm_resource_group.star-server.name
}

resource "azurerm_subnet" "this" {
  name                 = "sv-net"
  resource_group_name  = "star-server"
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = ["10.0.1.0/24"]
  service_endpoints    = ["Microsoft.Storage"]
}
