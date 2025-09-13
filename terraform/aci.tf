# Auth Service en Azure Container Instance
resource "azurerm_container_group" "auth" {
  name                = "auth-service"
  location            = var.location
  resource_group_name = var.resource_group_name
  ip_address_type     = "Private"
  network_profile_id  = azurerm_network_profile.aci.id
  os_type             = "Linux"
  subnet_ids          = [module.network.auth_subnet_id]

  container {
    name   = "auth-container"
    image  = "your-dockerhub-repo/auth-service:latest"
    cpu    = "1"
    memory = "1.5"
    port   = 3000

    environment_variables = {
      PORT                  = "3000"
      DB_HOST               = azurerm_postgresql_server.auth.fully_qualified_domain_name
      DB_NAME               = azurerm_postgresql_database.auth.name
      DB_USER               = "${azurerm_postgresql_server.auth.administrator_login}@${azurerm_postgresql_server.auth.name}"
      DB_PASSWORD           = var.postgres_auth_password
      REDIS_HOST            = azurerm_redis_cache.main.hostname
      REDIS_PORT            = "6380"
      REDIS_PASSWORD        = azurerm_redis_cache.main.primary_access_key
    }
  }
}

# Users Service en Azure Container Instance
resource "azurerm_container_group" "users" {
  name                = "users-service"
  location            = var.location
  resource_group_name = var.resource_group_name
  ip_address_type     = "Private"
  network_profile_id  = azurerm_network_profile.aci.id
  os_type             = "Linux"
  subnet_ids          = [module.network.users_subnet_id]

  container {
    name   = "users-container"
    image  = "your-dockerhub-repo/users-service:latest"
    cpu    = "1"
    memory = "1.5"
    port   = 8080

    environment_variables = {
      SERVER_PORT           = "8080"
      SPRING_DATASOURCE_URL = "jdbc:postgresql://${azurerm_postgresql_server.users.fully_qualified_domain_name}:5432/${azurerm_postgresql_database.users.name}"
      SPRING_DATASOURCE_USERNAME = "${azurerm_postgresql_server.users.administrator_login}@${azurerm_postgresql_server.users.name}"
      SPRING_DATASOURCE_PASSWORD = var.postgres_users_password
      SPRING_REDIS_HOST     = azurerm_redis_cache.main.hostname
      SPRING_REDIS_PORT     = "6380"
      SPRING_REDIS_PASSWORD = azurerm_redis_cache.main.primary_access_key
    }
  }
}

# Todos Service en Azure Container Instance
resource "azurerm_container_group" "todos" {
  name                = "todos-service"
  location            = var.location
  resource_group_name = var.resource_group_name
  ip_address_type     = "Private"
  network_profile_id  = azurerm_network_profile.aci.id
  os_type             = "Linux"
  subnet_ids          = [module.network.todos_subnet_id]

  container {
    name   = "todos-container"
    image  = "your-dockerhub-repo/todos-service:latest"
    cpu    = "1"
    memory = "1.5"
    port   = 4000

    environment_variables = {
      PORT                  = "4000"
      DB_HOST               = azurerm_postgresql_server.todos.fully_qualified_domain_name
      DB_NAME               = azurerm_postgresql_database.todos.name
      DB_USER               = "${azurerm_postgresql_server.todos.administrator_login}@${azurerm_postgresql_server.todos.name}"
      DB_PASSWORD           = var.postgres_todos_password
      REDIS_HOST            = azurerm_redis_cache.main.hostname
      REDIS_PORT            = "6380"
      REDIS_PASSWORD        = azurerm_redis_cache.main.primary_access_key
    }
  }
}

# Network Profile para ACI
resource "azurerm_network_profile" "aci" {
  name                = "aci-network-profile"
  location            = var.location
  resource_group_name = var.resource_group_name
  container_network_interface {
    name = "aci-network-interface"

    ip_configuration {
      name      = "ip-configuration"
      subnet_id = module.network.auth_subnet_id
    }
  }
}