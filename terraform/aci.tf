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
      AUTH_API_PORT                       = "8000"
      USERS_API_ADDRESS                   = "http://${azurerm_container_group.users.ip_address}:8083"
      JWT_SECRET                          = "PRFT"
      REDIS_HOST                          = "${module.security.redis_cache_hostname}"
      REDIS_PASSWORD                      = "${module.security.redis_cache_primary_key}"
      REDIS_PORT                          = "6380"
      SPRING_REDIS_HOST                   = "${module.security.redis_cache_hostname}"
      SPRING_REDIS_PASSWORD               = "${module.security.redis_cache_primary_key}"
      SPRING_REDIS_PORT                   = "6380"
      SPRING_REDIS_SSL                    = "true"
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
      USERS_API_PORT                      = "8083"
      JWT_SECRET                          = "PRFT"
      REDIS_HOST                          = "${module.security.redis_cache_hostname}"
      REDIS_PASSWORD                      = "${module.security.redis_cache_primary_key}"
      REDIS_PORT                          = "6380"
      SPRING_REDIS_HOST                   = "${module.security.redis_cache_hostname}"
      SPRING_REDIS_PASSWORD               = "${module.security.redis_cache_primary_key}"
      SPRING_REDIS_PORT                   = "6380"
      SPRING_REDIS_SSL                    = "true"
      DB_HOST                             = "${azurerm_postgresql_flexible_server.consolidated.fqdn}"
      DB_NAME                             = "usersdb"
      DB_USER                             = "${azurerm_postgresql_flexible_server.consolidated.administrator_login}"
      DB_PASSWORD                         = "${azurerm_postgresql_flexible_server.consolidated.administrator_password}"
      DB_PORT                             = "5432"
      SPRING_DATASOURCE_URL               = "jdbc:postgresql://${azurerm_postgresql_flexible_server.consolidated.fqdn}:5432/usersdb?sslmode=require"
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
      TODOS_API_PORT                      = "8082"
      JWT_SECRET                          = "PRFT"
      REDIS_HOST                          = "${module.security.redis_cache_hostname}"
      REDIS_PASSWORD                      = "${module.security.redis_cache_primary_key}"
      REDIS_PORT                          = "6380"
      SPRING_REDIS_HOST                   = "${module.security.redis_cache_hostname}"
      SPRING_REDIS_PASSWORD               = "${module.security.redis_cache_primary_key}"
      SPRING_REDIS_PORT                   = "6380"
      SPRING_REDIS_SSL                    = "true"
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

    # CORRECCIÓN: Usar IP pública del Application Gateway con rutas correctas
    environment_variables = {
      AUTH_API_ADDRESS  = "http://${data.azurerm_public_ip.appgw.ip_address}/api/auth"
      TODOS_API_ADDRESS = "http://${data.azurerm_public_ip.appgw.ip_address}/api/todos"
      USERS_API_ADDRESS = "http://${data.azurerm_public_ip.appgw.ip_address}/api/users"
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
