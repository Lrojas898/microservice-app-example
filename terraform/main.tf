
# Grupo de recursos principal
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.resource_group_location
}

# Módulo de redes
module "network" {
  source = "./modules/network"

  resource_group_name              = azurerm_resource_group.main.name
  location                         = var.resource_group_location
  vnet_address_space               = var.vnet_address_space
  auth_subnet_prefix               = var.auth_subnet_prefix
  users_subnet_prefix              = var.users_subnet_prefix
  todos_subnet_prefix              = var.todos_subnet_prefix
  gateway_subnet_prefix            = var.gateway_subnet_prefix
  cache_subnet_prefix              = var.cache_subnet_prefix
  auth_container_subnet_prefix     = var.auth_container_subnet_prefix
  users_container_subnet_prefix    = var.users_container_subnet_prefix
  todos_container_subnet_prefix    = var.todos_container_subnet_prefix
  frontend_container_subnet_prefix = var.frontend_container_subnet_prefix
}

# Módulo de seguridad
module "security" {
  source = "./modules/security"

  resource_group_name = azurerm_resource_group.main.name
  location            = var.resource_group_location
  cache_subnet_id     = module.network.cache_subnet_id
  gateway_subnet_id   = module.network.gateway_subnet_id
}
