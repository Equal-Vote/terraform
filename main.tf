terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
    }
  }
  backend "azurerm" {
    resource_group_name  = "tfstate"
    storage_account_name = "starserverinfra"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "star-server" {
  name     = "star-server"
  location = "West US 2"
}

resource "azurerm_log_analytics_workspace" "star-server" {
  name                = "star-server"
  location            = azurerm_resource_group.star-server.location
  resource_group_name = azurerm_resource_group.star-server.name
  retention_in_days   = 30
}

resource "azurerm_container_app_environment" "dev" {
  name                       = "dev"
  location                   = azurerm_resource_group.star-server.location
  resource_group_name        = azurerm_resource_group.star-server.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.star-server.id
}

# Azure Container App name must be unique, even if it's in another Resource Group.
resource "azurerm_container_app" "star-server" {

  # A custom domain and binding were manually added to this app. When Terraform
  # is run, it will destroy the custom_domain, because the module isn't
  # compatible with "managedCertificates" - see
  # https://github.com/hashicorp/terraform-provider-azurerm/issues/21866. This
  # ignore_changes block was added to prevent Terraform from breaking the
  # custom_domain.
  lifecycle {
    ignore_changes = [
      ingress[0].custom_domain,
    ]
  }

  name                         = "star-server"
  container_app_environment_id = azurerm_container_app_environment.dev.id
  resource_group_name          = azurerm_resource_group.star-server.name
  revision_mode                = "Single"

  ingress {

    #custom_domain {
    #  certificate_binding_type = "SniEnabled"
    #  certificate_id           = "/subscriptions/86f3145a-48cc-4255-8757-dd3104d15e57/resourceGroups/star-server/providers/Microsoft.App/managedEnvironments/dev/managedCertificates/dev.star.vote-dev-230729000442"
    #  name                     = "dev.star.vote"
    #}

    external_enabled = true
    target_port      = 5000
    traffic_weight {

      # WARNING!
      #
      # You must set latest_revision = true or this will fail on initial
      # deploy. I wasted hours of my life trying to figure this out. Hours that
      # I could have spent hanging out with my children... shaping them into
      # better people than I could ever be... people that don't write code with
      # such diabolical, evil, bugs like this one:
      #
      # https://github.com/hashicorp/terraform-provider-azurerm/issues/20435
      #
      latest_revision = true

      percentage = "100"
    }
  }

  secret {
    name  = "database-url"
    value = var.DATABASE_URL
  }
  secret {
    name  = "keycloak-secret"
    value = var.KEYCLOAK_SECRET
  }
  secret {
    name  = "s3-secret"
    value = var.S3_SECRET
  }
  secret {
    name  = "sendgrid-api-key"
    value = var.SENDGRID_API_KEY
  }

  template {
    min_replicas = 1
    container {
      env {
        name  = "ALLOWED_URLS"
        value = var.ALLOWED_URLS
      }
      env {
        name        = "DATABASE_URL"
        secret_name = "database-url"
      }
      env {
        name  = "DEV_DATABASE"
        value = var.DEV_DATABASE
      }
      env {
        name  = "KEYCLOAK_PUBLIC_KEY"
        value = var.KEYCLOAK_PUBLIC_KEY
      }
      env {
        name        = "KEYCLOAK_SECRET"
        secret_name = "keycloak-secret"
      }
      env {
        name  = "KEYCLOAK_URL"
        value = var.KEYCLOAK_URL
      }
      env {
        name  = "REACT_APP_KEYCLOAK_URL"
        value = var.KEYCLOAK_URL
      }
      env {
        name  = "REACT_APP_FF_ELECTION_ROLES"
        value = var.REACT_APP_FF_ELECTION_ROLES
      }
      env {
        name  = "REACT_APP_FF_METHOD_STAR_PR"
        value = var.REACT_APP_FF_METHOD_STAR_PR
      }
      env {
        name  = "REACT_APP_FF_METHOD_RANKED_ROBIN"
        value = var.REACT_APP_FF_METHOD_RANKED_ROBIN
      }
      env {
        name  = "REACT_APP_FF_METHOD_APPROVAL"
        value = var.REACT_APP_FF_METHOD_APPROVAL
      }
      env {
        name  = "REACT_APP_FF_METHOD_RANKED_CHOICE"
        value = var.REACT_APP_FF_METHOD_RANKED_CHOICE
      }
      env {
        name  = "REACT_APP_FF_CANDIDATE_DETAILS"
        value = var.REACT_APP_FF_CANDIDATE_DETAILS
      }
      env {
        name  = "REACT_APP_FF_CANDIDATE_PHOTOS"
        value = var.REACT_APP_FF_CANDIDATE_PHOTOS
      }
      env {
        name  = "REACT_APP_FF_PRECINCTS"
        value = var.REACT_APP_FF_PRECINCTS
      }
      env {
        name  = "REACT_APP_FF_MULTI_RACE"
        value = var.REACT_APP_FF_MULTI_RACE
      }
      env {
        name  = "REACT_APP_FF_MULTI_WINNER"
        value = var.REACT_APP_FF_MULTI_WINNER
      }
      env {
        name  = "REACT_APP_FF_CUSTOM_REGISTRATION"
        value = var.REACT_APP_FF_CUSTOM_REGISTRATION
      }
      env {
        name  = "REACT_APP_FF_VOTER_FLAGGING"
        value = var.REACT_APP_FF_VOTER_FLAGGING
      }
      env {
        name  = "S3_ID"
        value = var.S3_ID
      }
      env {
        name        = "S3_SECRET"
        secret_name = "s3-secret"
      }
      env {
        name        = "SENDGRID_API_KEY"
        secret_name = "sendgrid-api-key"
      }
      name   = "star-server"
      image  = var.CONTAINER_IMAGE
      cpu    = 0.25
      memory = "0.5Gi"
    }
  }
}

# This code isn't working because the Azure Terraform module has a bug!
#
# https://github.com/hashicorp/terraform-provider-azurerm/issues/21522
#
# I tried to create the server in the Azure Portal and I got a different error
# saying that, "Azure subscription 1 is not allowed to provision in West US 2",
# so I'm going to try this code with just West US.
#
# Yeah that didn't work, so I'm just going to try to create the server manually
# in West US and I'll import it later if/when they fix this bug.
#resource "azurerm_postgresql_flexible_server" "star-server" {
#  administrator_login    = "psqladmin"
#  administrator_password = var.PGPASSWORD
#  backup_retention_days  = 7
#  location               = azurerm_resource_group.star-server.location
#  name                = "star-server-psqlflexibleserver"
#  resource_group_name = azurerm_resource_group.star-server.name
#
#  # The docs are a lie! sku_name is not optional!
#  sku_name = B_Standard_B1ms
#
#  storage_mb = 32768
#}
