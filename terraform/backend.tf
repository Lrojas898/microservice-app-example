
terraform {
  backend "azurerm" {
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "ingesoftvtstatestorage"
    container_name       = "tfstate"
    key                  = "prod.terraform.tfstate"
  }
}
