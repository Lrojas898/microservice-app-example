terraform {
  required_version = ">= 1.5.7"

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

provider "azurerm" {
  features {}

  # Usa credenciales explícitas desde GitHub Secrets (pasadas como variables)
  subscription_id = var.subscriptionId
  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id

  # Fuerza a no usar Azure CLI (recomendado en CI/CD)
  use_cli = false
}