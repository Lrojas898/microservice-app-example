# Obtener la IP pública del Application Gateway
data "azurerm_public_ip" "appgw" {
  name                = "appgw-public-ip"
  resource_group_name = var.resource_group_name
}

# Container Groups únicamente - SIN Redis ni Application Gateway
resource "azurerm_container_group" "auth" {
  name                = "auth-service"
  location            = var.location
  resource_group_name = var.resource_group_name
  ip_address_type     = "Private"
  os_type             = "Linux"
  subnet_ids          = [module.network.auth_container_subnet_id]

  container {
    name   = "auth-container"
    image  = var.auth_api_image
    cpu    = "0.5"
    memory = "1"

    ports {
      port     = 8000
      protocol = "TCP"
    }

    environment_variables = {
      AUTH_API_PORT     = "8000"
      USERS_API_ADDRESS = "http://${azurerm_container_group.users.ip_address}:8083"
      JWT_SECRET        = "PRFT"
    }
  }

  image_registry_credential {
    server   = "index.docker.io"
    username = var.dockerhub_username
    password = var.dockerhub_token
  }

  depends_on = [
    module.network,
    azurerm_postgresql_flexible_server.consolidated
  ]
}

# Users Service
resource "azurerm_container_group" "users" {
  name                = "users-service"
  location            = var.location
  resource_group_name = var.resource_group_name
  ip_address_type     = "Private"
  os_type             = "Linux"
  subnet_ids          = [module.network.users_container_subnet_id]

  container {
    name   = "users-container"
    image  = var.users_api_image
    cpu    = "0.5"
    memory = "1"

    ports {
      port     = 8083
      protocol = "TCP"
    }

    environment_variables = {
      USERS_API_PORT = "8083"
      JWT_SECRET     = "PRFT"
    }
  }

  image_registry_credential {
    server   = "index.docker.io"
    username = var.dockerhub_username
    password = var.dockerhub_token
  }

  depends_on = [
    module.network,
    azurerm_postgresql_flexible_server.consolidated
  ]
}

# Todos Service
resource "azurerm_container_group" "todos" {
  name                = "todos-service"
  location            = var.location
  resource_group_name = var.resource_group_name
  ip_address_type     = "Private"
  os_type             = "Linux"
  subnet_ids          = [module.network.todos_container_subnet_id]

  container {
    name   = "todos-container"
    image  = var.todos_api_image
    cpu    = "0.5"
    memory = "1"

    ports {
      port     = 8082
      protocol = "TCP"
    }

    environment_variables = {
      TODOS_API_PORT = "8082"
      JWT_SECRET     = "PRFT"
    }
  }

  image_registry_credential {
    server   = "index.docker.io"
    username = var.dockerhub_username
    password = var.dockerhub_token
  }

  depends_on = [
    module.network,
    azurerm_postgresql_flexible_server.consolidated
  ]
}

# Frontend Service
resource "azurerm_container_group" "frontend" {
  name                = "frontend-service"
  location            = var.location
  resource_group_name = var.resource_group_name
  ip_address_type     = "Private"
  os_type             = "Linux"
  subnet_ids          = [module.network.frontend_container_subnet_id]

  container {
    name   = "frontend-container"
    image  = var.frontend_image
    cpu    = "0.25"
    memory = "0.5"

    ports {
      port     = 80
      protocol = "TCP"
    }

    # CORRECCIÓN: Usar IP pública del Application Gateway
    environment_variables = {
      AUTH_API_ADDRESS  = "http://${data.azurerm_public_ip.appgw.ip_address}"
      TODOS_API_ADDRESS = "http://${data.azurerm_public_ip.appgw.ip_address}"
      USERS_API_ADDRESS = "http://${data.azurerm_public_ip.appgw.ip_address}"
    }
  }

  image_registry_credential {
    server   = "index.docker.io"
    username = var.dockerhub_username
    password = var.dockerhub_token
  }

  depends_on = [
    module.network,
    azurerm_container_group.auth,
    azurerm_container_group.todos,
    azurerm_container_group.users
  ]
}
