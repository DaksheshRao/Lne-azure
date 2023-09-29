terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.74.0"
    }
  }
}

provider "azurerm" {
  subscription_id = var.SUBSCRIPTION_ID
  client_id       = var.CLIENT_ID
  client_secret   = var.CLIENT_SECRET
  tenant_id       = var.TENANT_ID
  features {}
}