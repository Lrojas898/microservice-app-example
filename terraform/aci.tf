# Application Gateway removido - acceso directo a servicios

# Container Groups únicamente - SIN Redis ni Application Gateway

# Zipkin Service for Distributed Tracing
resource "azurerm_container_group" "zipkin" {
  name                = "zipkin-service"
  location            = var.location
  resource_group_name = var.resource_group_name
  ip_address_type     = "Public"
  os_type             = "Linux"

  container {
    name   = "zipkin-container"
    image  = "openzipkin/zipkin:latest"
    cpu    = "0.5"
    memory = "1"

    ports {
      port     = 9411
      protocol = "TCP"
    }

    environment_variables = {
      STORAGE_TYPE = "mem"
      JAVA_OPTS    = "-Xms512m -Xmx1024m"
    }
  }

  tags = {
    Environment = "production"
    Service     = "zipkin"
  }

  depends_on = [
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
      USERS_API_ADDRESS                   = "http://users-service:8083"
      JWT_SECRET                          = "myfancysecret1234567890abcdef1234"
      ZIPKIN_URL                          = "http://zipkin-service:9411/api/v2/spans"
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
    azurerm_container_group.zipkin,
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
      ZIPKIN_URL     = "http://zipkin-service:9411/api/v2/spans"
    }
  }

  image_registry_credential {
    server   = "index.docker.io"
    username = var.dockerhub_username
    password = var.dockerhub_token
  }

  depends_on = [
    azurerm_resource_group.main,
    azurerm_container_group.zipkin
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
      ZIPKIN_URL                          = "http://zipkin-service:9411/api/v2/spans"
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
    azurerm_container_group.zipkin,
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
      ZIPKIN_URL     = "http://zipkin-service:9411/api/v2/spans"
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
    azurerm_container_group.zipkin,
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

    # CORRECCIÓN: Usar nombres de servicio para evitar dependencias circulares durante import
    environment_variables = {
      AUTH_API_ADDRESS  = "http://auth-service:8000"
      TODOS_API_ADDRESS = "http://todos-service:8082"
      ZIPKIN_URL        = "http://zipkin-service:9411/api/v2/spans"
    }
  }

  image_registry_credential {
    server   = "index.docker.io"
    username = var.dockerhub_username
    password = var.dockerhub_token
  }

  depends_on = [
    azurerm_resource_group.main,
    azurerm_container_group.auth,
    azurerm_container_group.todos,
    azurerm_container_group.users,
    azurerm_container_group.zipkin
  ]
}
