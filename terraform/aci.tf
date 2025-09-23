# Obtener la IP pública del Application Gateway
data "azurerm_public_ip" "appgw" {
  name                = "appgw-public-ip"
  resource_group_name = var.resource_group_name
}

# Optimización de Costos: Container Groups con recursos reducidos
# Ahorro estimado: ~50% en costos de contenedores

# Auth Service - Recursos reducidos
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
    cpu    = "0.5" # Reducido de 1 a 0.5
    memory = "1"   # Reducido de 1.5 a 1GB

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

# Users Service - Recursos reducidos
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
    cpu    = "0.5" # Reducido de 1 a 0.5
    memory = "1"   # Reducido de 1.5 a 1GB

    ports {
      port     = 8083
      protocol = "TCP"
    }

    environment_variables = {
      SERVER_PORT = "8083"
      JWT_SECRET  = "PRFT"
      # Conexión al servidor consolidado - CORREGIDO para PostgreSQL Flexible Server
      SPRING_DATASOURCE_URL      = "jdbc:postgresql://${azurerm_postgresql_flexible_server.consolidated.name}.privatelink.postgres.database.azure.com:5432/usersdb?sslmode=require"
      SPRING_DATASOURCE_USERNAME = azurerm_postgresql_flexible_server.consolidated.administrator_login
      SPRING_DATASOURCE_PASSWORD = random_password.postgres_consolidated_password.result
      SPRING_REDIS_HOST          = module.security.redis_cache_hostname
      SPRING_REDIS_PORT          = "6380"
      SPRING_REDIS_PASSWORD      = module.security.redis_cache_primary_key
      SPRING_REDIS_SSL           = "true"
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

# Todos Service - Recursos reducidos
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
    cpu    = "0.5" # Reducido de 1 a 0.5
    memory = "1"   # Reducido de 1.5 a 1GB

    ports {
      port     = 8082
      protocol = "TCP"
    }

    environment_variables = {
      PORT = "8082"
      # Conexión al servidor consolidado
      DB_HOST        = "${azurerm_postgresql_flexible_server.consolidated.name}.privatelink.postgres.database.azure.com"
      DB_NAME        = "todosdb"
      DB_USER        = azurerm_postgresql_flexible_server.consolidated.administrator_login
      DB_PASSWORD    = random_password.postgres_consolidated_password.result
      REDIS_HOST     = module.security.redis_cache_hostname
      REDIS_PORT     = "6380"
      REDIS_PASSWORD = module.security.redis_cache_primary_key
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

# Frontend Service - CORREGIDO para usar IP pública del Application Gateway
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
    cpu    = "0.25" # Muy reducido para nginx
    memory = "0.5"  # Muy reducido para nginx

    ports {
      port     = 80
      protocol = "TCP"
    }

    # CORRECCIÓN CRÍTICA: Usar IP pública del Application Gateway en lugar de IPs privadas
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
