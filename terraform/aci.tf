# Auth Service en Azure Container Instance
resource "azurerm_container_group" "auth" {
  name                = "auth-service"
  location            = var.location
  resource_group_name = var.resource_group_name
  ip_address_type     = "Private"
  os_type             = "Linux"
  subnet_ids          = [module.network.auth_subnet_id]

  container {
    name   = "auth-container"
    image  = "osgomez/auth-service:latest"
    cpu    = "1"
    memory = "1.5"

    # ¡CORRECCIÓN IMPORTANTE! Usa el bloque "ports" en lugar de "port"
    ports {
      port     = 8000
      protocol = "TCP"
    }

    environment_variables = {
      PORT           = "8000"
      DB_HOST        = azurerm_postgresql_flexible_server.auth.fqdn
      DB_NAME        = "authdb"
      DB_USER        = azurerm_postgresql_flexible_server.auth.administrator_login
      DB_PASSWORD    = var.postgres_auth_password
      REDIS_HOST     = module.security.redis_cache_hostname
      REDIS_PORT     = "6380"
      REDIS_PASSWORD = module.security.redis_cache_primary_key
    }
  }
}

# Users Service en Azure Container Instance
resource "azurerm_container_group" "users" {
  name                = "users-service"
  location            = var.location
  resource_group_name = var.resource_group_name
  ip_address_type     = "Private"
  os_type             = "Linux"
  subnet_ids          = [module.network.users_subnet_id]

  container {
    name   = "users-container"
    image  = "osgomez/users-service:latest"
    cpu    = "1"
    memory = "1.5"

    # ¡CORRECCIÓN IMPORTANTE! Usa el bloque "ports" en lugar de "port"
    ports {
      port     = 8083
      protocol = "TCP"
    }

    environment_variables = {
      SERVER_PORT                = "8083"
      SPRING_DATASOURCE_URL      = "jdbc:postgresql://${azurerm_postgresql_flexible_server.users.fqdn}:5432/usersdb"
      SPRING_DATASOURCE_USERNAME = azurerm_postgresql_flexible_server.users.administrator_login
      SPRING_DATASOURCE_PASSWORD = var.postgres_users_password
      SPRING_REDIS_HOST          = module.security.redis_cache_hostname
      SPRING_REDIS_PORT          = "6380"
      SPRING_REDIS_PASSWORD      = module.security.redis_cache_primary_key
    }
  }
}

# Todos Service en Azure Container Instance
resource "azurerm_container_group" "todos" {
  name                = "todos-service"
  location            = var.location
  resource_group_name = var.resource_group_name
  ip_address_type     = "Private"
  os_type             = "Linux"
  subnet_ids          = [module.network.todos_subnet_id]

  container {
    name   = "todos-container"
    image  = "osgomez/todos-service:latest"
    cpu    = "1"
    memory = "1.5"

    # ¡CORRECCIÓN IMPORTANTE! Usa el bloque "ports" en lugar de "port"
    ports {
      port     = 8082
      protocol = "TCP"
    }

    environment_variables = {
      PORT           = "8082"
      DB_HOST        = azurerm_postgresql_flexible_server.todos.fqdn
      DB_NAME        = "todosdb"
      DB_USER        = azurerm_postgresql_flexible_server.todos.administrator_login
      DB_PASSWORD    = var.postgres_todos_password
      REDIS_HOST     = module.security.redis_cache_hostname
      REDIS_PORT     = "6380"
      REDIS_PASSWORD = module.security.redis_cache_primary_key
    }
  }
}
