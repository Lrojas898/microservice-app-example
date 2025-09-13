# Grupo de recursos principal
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
}

# Incluye los módulos de red
module "network" {
  source = "./modules/network"
  
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  vnet_address_space  = var.vnet_address_space
  auth_subnet_prefix  = var.auth_subnet_prefix
  users_subnet_prefix = var.users_subnet_prefix
  todos_subnet_prefix = var.todos_subnet_prefix
  gateway_subnet_prefix = var.gateway_subnet_prefix
  cache_subnet_prefix = var.cache_subnet_prefix
}

# Incluye los recursos de seguridad
module "security" {
  source = "./modules/security"
  
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  vnet_id             = module.network.vnet_id
}