# Grupo de recursos principal
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.resource_group_location
}
#COMENTARIO DE PRUEBA CAMBIO DE INFRASTRUCTURA
# Módulo de red
module "network" {
  source = "./modules/network"

  resource_group_name = azurerm_resource_group.main.name
  location            = var.resource_group_location
  vnet_address_space  = var.vnet_address_space
  auth_subnet_prefix  = var.auth_subnet_prefix
  users_subnet_prefix = var.users_subnet_prefix
  todos_subnet_prefix = var.todos_subnet_prefix
  cache_subnet_prefix = var.cache_subnet_prefix
}

# Módulo de seguridad
module "security" {
  source = "./modules/security"

  resource_group_name = azurerm_resource_group.main.name
  location            = var.resource_group_location
  cache_subnet_id     = module.network.cache_subnet_id
  vnet_id             = module.network.vnet_id
  unique_suffix       = random_string.unique.result
}

resource "random_string" "unique" {
  length  = 8
  special = false
  upper   = false
  keepers = {
    region    = var.db_location
    timestamp = "20250927"
  }
}
