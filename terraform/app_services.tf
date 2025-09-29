# App Service Plan - Compartido para todos los servicios
resource "azurerm_service_plan" "main" {
  name                = "microservice-plan-${random_string.unique.result}"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  os_type             = "Linux"
  sku_name            = "B1"  # Basic - Rápido y económico
}

# Users Service
resource "azurerm_linux_web_app" "users" {
  name                = "users-service-${random_string.unique.result}"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  service_plan_id     = azurerm_service_plan.main.id

  site_config {
    application_stack {
      docker_image_name   = var.users_api_image
      docker_registry_url = "https://index.docker.io"
      docker_registry_username = var.dockerhub_username
      docker_registry_password = var.dockerhub_token
    }

    app_command_line = ""
  }

  app_settings = {
    "USERS_API_PORT"    = "8083"
    "JWT_SECRET"        = "myfancysecret1234567890abcdef1234"
    "WEBSITES_PORT"     = "8083"
  }
}

# Auth Service
resource "azurerm_linux_web_app" "auth" {
  name                = "auth-service-${random_string.unique.result}"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  service_plan_id     = azurerm_service_plan.main.id

  site_config {
    application_stack {
      docker_image_name   = var.auth_api_image
      docker_registry_url = "https://index.docker.io"
      docker_registry_username = var.dockerhub_username
      docker_registry_password = var.dockerhub_token
    }
  }

  app_settings = {
    "AUTH_API_PORT"                       = "8000"
    "USERS_API_ADDRESS"                   = "https://${azurerm_linux_web_app.users.default_hostname}"
    "JWT_SECRET"                          = "myfancysecret1234567890abcdef1234"
    "REDIS_HOST"                          = module.security.redis_cache_hostname
    "REDIS_PASSWORD"                      = module.security.redis_cache_primary_key
    "REDIS_PORT"                          = "6379"
    "SPRING_REDIS_HOST"                   = module.security.redis_cache_hostname
    "SPRING_REDIS_PASSWORD"               = module.security.redis_cache_primary_key
    "SPRING_REDIS_PORT"                   = "6379"
    "SPRING_REDIS_SSL"                    = "false"
    "DB_HOST"                             = azurerm_postgresql_flexible_server.consolidated.fqdn
    "DB_NAME"                             = "authdb"
    "DB_USER"                             = azurerm_postgresql_flexible_server.consolidated.administrator_login
    "DB_PASSWORD"                         = azurerm_postgresql_flexible_server.consolidated.administrator_password
    "DB_PORT"                             = "5432"
    "SPRING_DATASOURCE_URL"               = "jdbc:postgresql://${azurerm_postgresql_flexible_server.consolidated.fqdn}:5432/authdb?sslmode=require"
    "SPRING_DATASOURCE_USERNAME"          = azurerm_postgresql_flexible_server.consolidated.administrator_login
    "SPRING_DATASOURCE_PASSWORD"          = azurerm_postgresql_flexible_server.consolidated.administrator_password
    "SPRING_DATASOURCE_DRIVER_CLASS_NAME" = "org.postgresql.Driver"
    "SPRING_JPA_HIBERNATE_DDL_AUTO"       = "update"
    "SPRING_JPA_SHOW_SQL"                 = "false"
    "SPRING_JPA_DATABASE_PLATFORM"        = "org.hibernate.dialect.PostgreSQLDialect"
    "WEBSITES_PORT"                       = "8000"
  }
}

# Todos Service
resource "azurerm_linux_web_app" "todos" {
  name                = "todos-service-${random_string.unique.result}"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  service_plan_id     = azurerm_service_plan.main.id

  site_config {
    application_stack {
      docker_image_name   = var.todos_api_image
      docker_registry_url = "https://index.docker.io"
      docker_registry_username = var.dockerhub_username
      docker_registry_password = var.dockerhub_token
    }
  }

  app_settings = {
    "TODOS_API_PORT"                      = "8082"
    "JWT_SECRET"                          = "myfancysecret1234567890abcdef1234"
    "REDIS_HOST"                          = module.security.redis_cache_hostname
    "REDIS_PASSWORD"                      = module.security.redis_cache_primary_key
    "REDIS_PORT"                          = "6379"
    "REDIS_CHANNEL"                       = "log_channel"
    "SPRING_REDIS_HOST"                   = module.security.redis_cache_hostname
    "SPRING_REDIS_PASSWORD"               = module.security.redis_cache_primary_key
    "SPRING_REDIS_PORT"                   = "6379"
    "SPRING_REDIS_SSL"                    = "false"
    "DB_HOST"                             = azurerm_postgresql_flexible_server.consolidated.fqdn
    "DB_NAME"                             = "todosdb"
    "DB_USER"                             = azurerm_postgresql_flexible_server.consolidated.administrator_login
    "DB_PASSWORD"                         = azurerm_postgresql_flexible_server.consolidated.administrator_password
    "DB_PORT"                             = "5432"
    "SPRING_DATASOURCE_URL"               = "jdbc:postgresql://${azurerm_postgresql_flexible_server.consolidated.fqdn}:5432/todosdb?sslmode=require"
    "SPRING_DATASOURCE_USERNAME"          = azurerm_postgresql_flexible_server.consolidated.administrator_login
    "SPRING_DATASOURCE_PASSWORD"          = azurerm_postgresql_flexible_server.consolidated.administrator_password
    "SPRING_DATASOURCE_DRIVER_CLASS_NAME" = "org.postgresql.Driver"
    "SPRING_JPA_HIBERNATE_DDL_AUTO"       = "update"
    "SPRING_JPA_SHOW_SQL"                 = "false"
    "SPRING_JPA_DATABASE_PLATFORM"        = "org.hibernate.dialect.PostgreSQLDialect"
    "WEBSITES_PORT"                       = "8082"
  }
}

# Frontend Service
resource "azurerm_linux_web_app" "frontend" {
  name                = "frontend-service-${random_string.unique.result}"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  service_plan_id     = azurerm_service_plan.main.id

  site_config {
    application_stack {
      docker_image_name   = var.frontend_image
      docker_registry_url = "https://index.docker.io"
      docker_registry_username = var.dockerhub_username
      docker_registry_password = var.dockerhub_token
    }
  }

  app_settings = {
    "AUTH_API_ADDRESS"  = "https://${azurerm_linux_web_app.auth.default_hostname}"
    "TODOS_API_ADDRESS" = "https://${azurerm_linux_web_app.todos.default_hostname}"
    "JWT_SECRET"        = "myfancysecret1234567890abcdef1234"
    "WEBSITES_PORT"     = "80"
  }
}

# Log Message Processor Service
resource "azurerm_linux_web_app" "log_processor" {
  name                = "log-processor-service-${random_string.unique.result}"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  service_plan_id     = azurerm_service_plan.main.id

  site_config {
    application_stack {
      docker_image_name   = var.log_processor_image
      docker_registry_url = "https://index.docker.io"
      docker_registry_username = var.dockerhub_username
      docker_registry_password = var.dockerhub_token
    }
  }

  app_settings = {
    "REDIS_HOST"     = module.security.redis_cache_hostname
    "REDIS_PASSWORD" = module.security.redis_cache_primary_key
    "REDIS_PORT"     = "6379"
    "REDIS_CHANNEL"  = "log_channel"
    "LOG_LEVEL"      = "INFO"
  }
}