# Red virtual principal
resource "azurerm_virtual_network" "main" {
  name                = "microservice-vnet"
  address_space       = var.vnet_address_space
  location            = var.location
  resource_group_name = var.resource_group_name
}

# Subnet para Auth Microservice
resource "azurerm_subnet" "auth" {
  name                 = "auth-db-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.auth_subnet_prefix]

  delegation {
    name = "postgresql-delegation"
    service_delegation {
      name    = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

# Subnet para Users Service
resource "azurerm_subnet" "users" {
  name                 = "users-db-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.users_subnet_prefix]

  delegation {
    name = "postgresql-delegation"
    service_delegation {
      name    = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

# Subnet para Todos Service
resource "azurerm_subnet" "todos" {
  name                 = "todos-db-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.todos_subnet_prefix]

  delegation {
    name = "postgresql-delegation"
    service_delegation {
      name    = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

# Application Gateway subnet removed - using direct public access

# Subnet para Azure Cache for Redis
resource "azurerm_subnet" "cache" {
  name                 = "cache-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.cache_subnet_prefix]
}

# Container subnets removed - using public IPs for direct access

# Network Security Groups removed - using public IPs with Azure default security
