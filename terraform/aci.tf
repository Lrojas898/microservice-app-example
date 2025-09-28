# Application Gateway removido - acceso directo a servicios

# Container Groups únicamente - SIN Redis ni Application Gateway

# Log Analytics Workspace para Container Apps
resource "azurerm_log_analytics_workspace" "zipkin" {
  name                = "zipkin-logs-${random_string.unique.result}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = 7

  tags = {
    Environment = "production"
    Service     = "zipkin-monitoring"
  }

  depends_on = [azurerm_resource_group.main]
}

# Container Apps Environment
resource "azurerm_container_app_environment" "zipkin" {
  name                       = "zipkin-env-${random_string.unique.result}"
  location                   = var.location
  resource_group_name        = var.resource_group_name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.zipkin.id

  tags = {
    Environment = "production"
    Service     = "zipkin-environment"
  }

  depends_on = [azurerm_resource_group.main]
}

# Zipkin Container App - ULTRA OPTIMIZADO
resource "azurerm_container_app" "zipkin" {
  name                         = "zipkin-app"
  container_app_environment_id = azurerm_container_app_environment.zipkin.id
  resource_group_name          = var.resource_group_name
  revision_mode                = "Single"

  template {
    min_replicas = 1
    max_replicas = 1

    container {
      name   = "zipkin"
      image  = "openzipkin/zipkin-slim:latest"
      cpu    = 0.25 # Muy bajo para startup rápido
      memory = "0.5Gi"

      env {
        name  = "STORAGE_TYPE"
        value = "mem"
      }
      env {
        name  = "JAVA_OPTS"
        value = "-Xms128m -Xmx256m -XX:+UseSerialGC -Djava.security.egd=file:/dev/./urandom -XX:TieredStopAtLevel=1"
      }
      env {
        name  = "LOGGING_LEVEL_ROOT"
        value = "ERROR" # Logs mínimos para startup rápido
      }
      env {
        name  = "SELF_TRACING_ENABLED"
        value = "false"
      }

      # Health probes optimizados
      liveness_probe {
        http_get {
          path = "/api/v2/services"
          port = 9411
        }
        initial_delay_seconds = 15 # Reducido significativamente
        period_seconds        = 30
        timeout_seconds       = 5
        failure_threshold     = 3
      }

      readiness_probe {
        http_get {
          path = "/api/v2/services"
          port = 9411
        }
        initial_delay_seconds = 5 # Muy rápido
        period_seconds        = 10
        timeout_seconds       = 3
        failure_threshold     = 3
      }
    }
  }

  # Ingress para acceso externo
  ingress {
    external_enabled = true
    target_port      = 9411
    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  tags = {
    Environment = "production"
    Service     = "zipkin"
    Performance = "ultra-fast"
  }

  depends_on = [
    azurerm_container_app_environment.zipkin,
    azurerm_resource_group.main
  ]
}
resource "azurerm_container_group" "auth" {
  name                = "auth-service"
  location            = var.location
  resource_group_name = var.resource_group_name
  ip_address_type     = "Public"
  os_type             = "Linux"


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
      AUTH_API_PORT                       = "8000"
      USERS_API_ADDRESS                   = "http://${azurerm_container_group.users.ip_address}:8083"
      JWT_SECRET                          = "myfancysecret1234567890abcdef1234"
      ZIPKIN_URL                          = "https://${azurerm_container_app.zipkin.latest_revision_fqdn}/api/v2/spans"
      REDIS_HOST                          = "${module.security.redis_cache_hostname}"
      REDIS_PASSWORD                      = "${module.security.redis_cache_primary_key}"
      REDIS_PORT                          = "6379"
      SPRING_REDIS_HOST                   = "${module.security.redis_cache_hostname}"
      SPRING_REDIS_PASSWORD               = "${module.security.redis_cache_primary_key}"
      SPRING_REDIS_PORT                   = "6379"
      SPRING_REDIS_SSL                    = "false"
      DB_HOST                             = "${azurerm_postgresql_flexible_server.consolidated.fqdn}"
      DB_NAME                             = "authdb"
      DB_USER                             = "${azurerm_postgresql_flexible_server.consolidated.administrator_login}"
      DB_PASSWORD                         = "${azurerm_postgresql_flexible_server.consolidated.administrator_password}"
      DB_PORT                             = "5432"
      SPRING_DATASOURCE_URL               = "jdbc:postgresql://${azurerm_postgresql_flexible_server.consolidated.fqdn}:5432/authdb?sslmode=require"
      SPRING_DATASOURCE_USERNAME          = "${azurerm_postgresql_flexible_server.consolidated.administrator_login}"
      SPRING_DATASOURCE_PASSWORD          = "${azurerm_postgresql_flexible_server.consolidated.administrator_password}"
      SPRING_DATASOURCE_DRIVER_CLASS_NAME = "org.postgresql.Driver"
      SPRING_JPA_HIBERNATE_DDL_AUTO       = "update"
      SPRING_JPA_SHOW_SQL                 = "false"
      SPRING_JPA_DATABASE_PLATFORM        = "org.hibernate.dialect.PostgreSQLDialect"
    }
  }

  image_registry_credential {
    server   = "index.docker.io"
    username = var.dockerhub_username
    password = var.dockerhub_token
  }

  depends_on = [
    azurerm_resource_group.main,
    azurerm_postgresql_flexible_server.consolidated,
    module.security
  ]
}

# Users Service
resource "azurerm_container_group" "users" {
  name                = "users-service"
  location            = var.location
  resource_group_name = var.resource_group_name
  ip_address_type     = "Public"
  os_type             = "Linux"


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
      JWT_SECRET     = "myfancysecret1234567890abcdef1234"
      ZIPKIN_URL     = "https://${azurerm_container_app.zipkin.latest_revision_fqdn}/api/v2/spans"
    }
  }

  image_registry_credential {
    server   = "index.docker.io"
    username = var.dockerhub_username
    password = var.dockerhub_token
  }

  depends_on = [
    azurerm_resource_group.main
  ]
}

# Todos Service
resource "azurerm_container_group" "todos" {
  name                = "todos-service"
  location            = var.location
  resource_group_name = var.resource_group_name
  ip_address_type     = "Public"
  os_type             = "Linux"


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
      TODOS_API_PORT                      = "8082"
      JWT_SECRET                          = "myfancysecret1234567890abcdef1234"
      ZIPKIN_URL                          = "https://${azurerm_container_app.zipkin.latest_revision_fqdn}/api/v2/spans"
      REDIS_HOST                          = "${module.security.redis_cache_hostname}"
      REDIS_PASSWORD                      = "${module.security.redis_cache_primary_key}"
      REDIS_PORT                          = "6379"
      REDIS_CHANNEL                       = "log_channel"
      SPRING_REDIS_HOST                   = "${module.security.redis_cache_hostname}"
      SPRING_REDIS_PASSWORD               = "${module.security.redis_cache_primary_key}"
      SPRING_REDIS_PORT                   = "6379"
      SPRING_REDIS_SSL                    = "false"
      DB_HOST                             = "${azurerm_postgresql_flexible_server.consolidated.fqdn}"
      DB_NAME                             = "todosdb"
      DB_USER                             = "${azurerm_postgresql_flexible_server.consolidated.administrator_login}"
      DB_PASSWORD                         = "${azurerm_postgresql_flexible_server.consolidated.administrator_password}"
      DB_PORT                             = "5432"
      SPRING_DATASOURCE_URL               = "jdbc:postgresql://${azurerm_postgresql_flexible_server.consolidated.fqdn}:5432/todosdb?sslmode=require"
      SPRING_DATASOURCE_USERNAME          = "${azurerm_postgresql_flexible_server.consolidated.administrator_login}"
      SPRING_DATASOURCE_PASSWORD          = "${azurerm_postgresql_flexible_server.consolidated.administrator_password}"
      SPRING_DATASOURCE_DRIVER_CLASS_NAME = "org.postgresql.Driver"
      SPRING_JPA_HIBERNATE_DDL_AUTO       = "update"
      SPRING_JPA_SHOW_SQL                 = "false"
      SPRING_JPA_DATABASE_PLATFORM        = "org.hibernate.dialect.PostgreSQLDialect"
    }
  }

  image_registry_credential {
    server   = "index.docker.io"
    username = var.dockerhub_username
    password = var.dockerhub_token
  }

  depends_on = [
    azurerm_resource_group.main,
    azurerm_postgresql_flexible_server.consolidated,
    module.security
  ]
}

# Log Message Processor Service
resource "azurerm_container_group" "log_processor" {
  name                = "log-processor-service"
  location            = var.location
  resource_group_name = var.resource_group_name
  ip_address_type     = "None" # No public IP needed
  os_type             = "Linux"


  container {
    name   = "log-processor-container"
    image  = var.log_processor_image
    cpu    = "0.25"
    memory = "0.5"

    environment_variables = {
      REDIS_HOST     = "${module.security.redis_cache_hostname}"
      REDIS_PASSWORD = "${module.security.redis_cache_primary_key}"
      REDIS_PORT     = "6380"
      REDIS_CHANNEL  = "log_channel"
      ZIPKIN_URL     = "https://${azurerm_container_app.zipkin.latest_revision_fqdn}/api/v2/spans"
      LOG_LEVEL      = "INFO"
    }
  }

  image_registry_credential {
    server   = "index.docker.io"
    username = var.dockerhub_username
    password = var.dockerhub_token
  }

  depends_on = [
    azurerm_resource_group.main,
    module.security
  ]
}

# Frontend Service
resource "azurerm_container_group" "frontend" {
  name                = "frontend-service"
  location            = var.location
  resource_group_name = var.resource_group_name
  ip_address_type     = "Public"
  os_type             = "Linux"


  container {
    name   = "frontend-container"
    image  = var.frontend_image
    cpu    = "0.25"
    memory = "0.5"

    ports {
      port     = 80
      protocol = "TCP"
    }

    # CORRECCIÓN: Usar IPs públicas para comunicación entre servicios
    environment_variables = {
      AUTH_API_ADDRESS  = "http://${azurerm_container_group.auth.ip_address}:8000"
      TODOS_API_ADDRESS = "http://${azurerm_container_group.todos.ip_address}:8082"
      ZIPKIN_URL        = "https://${azurerm_container_app.zipkin.latest_revision_fqdn}/api/v2/spans"
    }
  }

  image_registry_credential {
    server   = "index.docker.io"
    username = var.dockerhub_username
    password = var.dockerhub_token
  }

  depends_on = [
    azurerm_resource_group.main
  ]
}
