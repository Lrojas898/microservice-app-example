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

# Subnet para Application Gateway
resource "azurerm_subnet" "gateway" {
  name                 = "gateway-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.gateway_subnet_prefix]
}

# Subnet para Azure Cache for Redis
resource "azurerm_subnet" "cache" {
  name                 = "cache-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.cache_subnet_prefix]
}

# Separate subnets for Container Instances (no delegation conflicts)
resource "azurerm_subnet" "auth_container" {
  name                 = "auth-container-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.auth_container_subnet_prefix]

  delegation {
    name = "container-delegation"
    service_delegation {
      name    = "Microsoft.ContainerInstance/containerGroups"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

resource "azurerm_subnet" "users_container" {
  name                 = "users-container-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.users_container_subnet_prefix]

  delegation {
    name = "container-delegation"
    service_delegation {
      name    = "Microsoft.ContainerInstance/containerGroups"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

resource "azurerm_subnet" "todos_container" {
  name                 = "todos-container-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.todos_container_subnet_prefix]

  delegation {
    name = "container-delegation"
    service_delegation {
      name    = "Microsoft.ContainerInstance/containerGroups"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

resource "azurerm_subnet" "frontend_container" {
  name                 = "frontend-container-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.frontend_container_subnet_prefix]

  delegation {
    name = "container-delegation"
    service_delegation {
      name    = "Microsoft.ContainerInstance/containerGroups"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

# Network Security Groups
resource "azurerm_network_security_group" "frontend_container" {
  name                = "frontend-container-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name

  # Allow HTTP traffic from Application Gateway subnet to frontend containers
  security_rule {
    name                       = "AllowAppGatewayToFrontend"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = var.gateway_subnet_prefix
    destination_address_prefix = var.frontend_container_subnet_prefix
  }

  # Allow health probe traffic from Application Gateway
  security_rule {
    name                       = "AllowAppGatewayHealthProbe"
    priority                   = 1100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "AzureLoadBalancer"
    destination_address_prefix = var.frontend_container_subnet_prefix
  }

  # Allow outbound internet access for container updates
  security_rule {
    name                       = "AllowOutboundInternet"
    priority                   = 1000
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = var.frontend_container_subnet_prefix
    destination_address_prefix = "Internet"
  }

  # Allow communication to other container subnets for API calls
  security_rule {
    name                       = "AllowToContainerSubnets"
    priority                   = 1200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["8000", "8080", "8082"]
    source_address_prefixes    = [var.auth_container_subnet_prefix, var.users_container_subnet_prefix, var.todos_container_subnet_prefix]
    destination_address_prefix = var.frontend_container_subnet_prefix
  }
}

resource "azurerm_network_security_group" "gateway" {
  name                = "gateway-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name

  # Allow HTTP traffic from internet
  security_rule {
    name                       = "AllowHttpFromInternet"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["80", "443"]
    source_address_prefix      = "Internet"
    destination_address_prefix = var.gateway_subnet_prefix
  }

  # Allow Application Gateway management traffic
  security_rule {
    name                       = "AllowGatewayManager"
    priority                   = 1100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "65200-65535"
    source_address_prefix      = "GatewayManager"
    destination_address_prefix = "*"
  }

  # Allow outbound to frontend containers
  security_rule {
    name                       = "AllowToFrontendContainers"
    priority                   = 1000
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = var.gateway_subnet_prefix
    destination_address_prefix = var.frontend_container_subnet_prefix
  }
}

# Network Security Group for Auth Container
resource "azurerm_network_security_group" "auth_container" {
  name                = "auth-container-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name

  # Allow HTTP traffic from Application Gateway subnet to auth containers
  security_rule {
    name                       = "AllowAppGatewayToAuth"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8000"
    source_address_prefix      = var.gateway_subnet_prefix
    destination_address_prefix = var.auth_container_subnet_prefix
  }

  # Allow traffic from frontend containers to auth service
  security_rule {
    name                       = "AllowFrontendToAuth"
    priority                   = 1100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8000"
    source_address_prefix      = var.frontend_container_subnet_prefix
    destination_address_prefix = var.auth_container_subnet_prefix
  }

  # Allow outbound traffic for database and external connections
  security_rule {
    name                       = "AllowOutbound"
    priority                   = 2000
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Network Security Group for Users Container
resource "azurerm_network_security_group" "users_container" {
  name                = "users-container-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name

  # Allow HTTP traffic from Application Gateway subnet to users containers
  security_rule {
    name                       = "AllowAppGatewayToUsers"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8083"
    source_address_prefix      = var.gateway_subnet_prefix
    destination_address_prefix = var.users_container_subnet_prefix
  }

  # Allow traffic from auth containers to users service
  security_rule {
    name                       = "AllowAuthToUsers"
    priority                   = 1100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8083"
    source_address_prefix      = var.auth_container_subnet_prefix
    destination_address_prefix = var.users_container_subnet_prefix
  }

  # Allow outbound traffic for database and external connections
  security_rule {
    name                       = "AllowOutbound"
    priority                   = 2000
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Network Security Group for Todos Container
resource "azurerm_network_security_group" "todos_container" {
  name                = "todos-container-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name

  # Allow HTTP traffic from Application Gateway subnet to todos containers
  security_rule {
    name                       = "AllowAppGatewayToTodos"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8082"
    source_address_prefix      = var.gateway_subnet_prefix
    destination_address_prefix = var.todos_container_subnet_prefix
  }

  # Allow traffic from frontend containers to todos service
  security_rule {
    name                       = "AllowFrontendToTodos"
    priority                   = 1100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8082"
    source_address_prefix      = var.frontend_container_subnet_prefix
    destination_address_prefix = var.todos_container_subnet_prefix
  }

  # Allow outbound traffic for database and external connections
  security_rule {
    name                       = "AllowOutbound"
    priority                   = 2000
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# NSG Associations
resource "azurerm_subnet_network_security_group_association" "frontend_container" {
  subnet_id                 = azurerm_subnet.frontend_container.id
  network_security_group_id = azurerm_network_security_group.frontend_container.id
}

resource "azurerm_subnet_network_security_group_association" "auth_container" {
  subnet_id                 = azurerm_subnet.auth_container.id
  network_security_group_id = azurerm_network_security_group.auth_container.id
}

resource "azurerm_subnet_network_security_group_association" "users_container" {
  subnet_id                 = azurerm_subnet.users_container.id
  network_security_group_id = azurerm_network_security_group.users_container.id
}

resource "azurerm_subnet_network_security_group_association" "todos_container" {
  subnet_id                 = azurerm_subnet.todos_container.id
  network_security_group_id = azurerm_network_security_group.todos_container.id
}

resource "azurerm_subnet_network_security_group_association" "gateway" {
  subnet_id                 = azurerm_subnet.gateway.id
  network_security_group_id = azurerm_network_security_group.gateway.id
}
