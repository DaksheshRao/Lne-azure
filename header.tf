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
    sas_token = var.key_value
  }
}

provider "azurerm" {
  subscription_id = var.subscription_id
  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id
  features {}
}