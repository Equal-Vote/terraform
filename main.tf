# Based on:
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_cluster

terraform {
  # Versions are hardcoded here so that every run resolves the same providers,
  # regardless of what `.terraform.lock.hcl` happens to contain. To upgrade,
  # bump the version below and run `tofu init -upgrade`.
  required_providers {
    azuread = {
      source  = "registry.opentofu.org/hashicorp/azuread"
      version = "3.9.0"
    }
    azurerm = {
      source  = "registry.opentofu.org/hashicorp/azurerm"
      version = "5.4.0"
    }
    kubernetes = {
      source  = "registry.opentofu.org/hashicorp/kubernetes"
      version = "3.2.1"
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

provider "azuread" {}

resource "azurerm_resource_group" "equalvote" {
  name     = "equalvote"
  location = "West US 2"
}

resource "azuread_group" "developers" {
  display_name     = "Developers"
  security_enabled = true
}

resource "azuread_group" "devops" {
  display_name     = "DevOps"
  security_enabled = true
}

resource "azurerm_kubernetes_cluster" "equalvote" {
  location            = azurerm_resource_group.equalvote.location
  name                = "equalvote"
  resource_group_name = azurerm_resource_group.equalvote.name
  dns_prefix          = "equalvote"

  # You can get available versions with this command:
  # az aks get-upgrades --resource-group equalvote --name equalvote --output table
  kubernetes_version = "1.36.3"

  # Enabling OIDC and Workload Identity so external-dns and cert-manager can manage DNS records in Azure DNS.
  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  # Enable Kubernetes RBAC with Azure AD integration
  role_based_access_control_enabled = true
  local_account_disabled            = true

  azure_active_directory_role_based_access_control {
    admin_group_object_ids = [regex("[^/]+$", azuread_group.devops.id)]
  }

  identity {
    type = "SystemAssigned"
  }

  # Required as of azurerm 5.x. "Manual" means we manage node pools ourselves
  # (the default_node_pool below), which is what this cluster already does.
  # "Auto" would hand provisioning to Karpenter-style node auto-provisioning.
  node_provisioning_profile {
    mode = "Manual"
  }

  default_node_pool {
    name                 = "agentpool"
    vm_size              = "Standard_D4ps_v6"
    node_count           = var.node_count
    orchestrator_version = "1.36"

    # Note: this pool leaves os_sku unset, which means the generic "Ubuntu"
    # SKU. AKS resolves that to Ubuntu 24.04 on Kubernetes 1.35+, so the nodes
    # are already on 24.04 -- the 1.35 upgrade rolled them off 22.04. 1.36 maps
    # to 24.04 as well, so this upgrade reimages the nodes without changing the
    # Ubuntu version. Don't pin os_sku = "Ubuntu2204"; AKS stops patching 22.04
    # on 2027-06-30.

    # This "optional" setting is needed if you ever want to actually change one
    # of like 15 other settings in your cluster. More Azure nonsense - just
    # create a new node pool with timestamp to make it unique or something. WTF
    # Azure!
    temporary_name_for_rotation = "wtfazure"

    # This pool is one node, so an upgrade surges it 1 -> 2. AKS joins the surge
    # node before it cordons anything, and max_unavailable stays at the API
    # default of 0 (azurerm 5.4.0 doesn't expose it), so the old node is drained
    # only once the new one is Ready. Cluster-wide the floor is this pool's node
    # plus lightpool's, and the two pools upgrade independently.
    upgrade_settings {
      max_surge = "1"
    }
  }

}

# Second node pool, in a different VM family from the default pool on purpose.
# Every VM family available to this subscription in West US 2 is capped at 10
# vCPU, and resizing a pool transiently needs twice its vCPU because AKS stands
# up a temporary pool before deleting the original. Two nodes in one family would
# need 16 and fail; one node in each of two families needs only 8 in either.
#
# HEADS UP: standardBpsv2Family is currently at limit 0 in West US 2 (4 vCPU
# grandfathered in, isQuotaApplicable true), and self-service increases are
# refused with QuotaNotAvailableForResource. Until a support request raises it to
# at least 8 -- 4 for this node, 4 so the pool can surge-upgrade or rotate --
# creating this pool fails with ErrCode_InsufficientVCPUQuota. The default pool
# is on Dpsv6, which does have quota, so it converges either way.
resource "azurerm_kubernetes_cluster_node_pool" "burst" {
  name                  = "burstpool"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.equalvote.id
  vm_size               = "Standard_B4ps_v2"
  node_count            = 1
  orchestrator_version  = "1.36"

  # System rather than User: with a single node in each pool, system addons have
  # to be schedulable on either one, or losing a pool strands them.
  mode = "System"

  # Same rotation dance as the default pool -- see the note there.
  temporary_name_for_rotation = "wtfazure2"

  upgrade_settings {
    max_surge = "1"
  }
}

# Azure RBAC: Allow DevOps and Developers groups to get credentials
resource "azurerm_role_assignment" "developers_aks_cluster_user" {
  scope                = azurerm_kubernetes_cluster.equalvote.id
  role_definition_name = "Azure Kubernetes Service Cluster User Role"
  principal_id         = azuread_group.developers.object_id
}

# Azure RBAC: Allow DevOps group to manage cluster (AKS admin role)
resource "azurerm_role_assignment" "devops_aks_cluster_admin" {
  scope                = azurerm_kubernetes_cluster.equalvote.id
  role_definition_name = "Azure Kubernetes Service RBAC Cluster Admin"
  principal_id         = azuread_group.devops.object_id
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

  # Was the `service_endpoints` list argument before azurerm 5.x.
  service_endpoint {
    service = "Microsoft.Storage"
  }
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
