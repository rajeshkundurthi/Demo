terraform {
  backend "azurerm" {
    resource_group_name  = "RG-DEMO"
    storage_account_name = "terraformgitconn"
    container_name       = "tfstate"
    key                  = "rg-deployment.tfstate"
  }
}