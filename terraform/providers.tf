terraform {
  required_version = ">= 1.5.7"

  # Backend remoto para almacenar el estado (comentado para desarrollo local)
  # Descomenta y configura cuando tengas un storage account
  # backend "azurerm" {
  #   resource_group_name  = "terraform-state-rg"
  #   storage_account_name = "terraformstate"
  #   container_name       = "tfstate"
  #   key                  = "microservice-app.tfstate"
  # }

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.113.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}