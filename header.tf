terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.74.0"
    }
  }
  backend "azurerm" {
    resource_group_name = "NetworkWatcherRG"
    storage_account_name = "cubatfstatestorage"
    container_name = "tfstate"
    key = "terraform.tfstate"
    sas_token = "lJQ9k0/K+qxL0TjTbeSaa7A4YLUoMmvnEV6LYOow+asvtQztT6CSdMDVsYVtCt4XfyMPsiEexAXz+AStZ39FPA=="
  }
}

provider "azurerm" {
  subscription_id = var.subscription_id
  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id
  features {}
}