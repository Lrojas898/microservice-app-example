# Generación de contraseñas aleatorias para las bases de datos
resource "random_password" "postgres_auth_password" {
  count   = var.postgres_auth_password == null ? 1 : 0
  length  = 16
  special = true
}

resource "random_password" "postgres_users_password" {
  count   = var.postgres_users_password == null ? 1 : 0
  length  = 16
  special = true
}

resource "random_password" "postgres_todos_password" {
  count   = var.postgres_todos_password == null ? 1 : 0
  length  = 16
  special = true
}

# PostgreSQL Flexible Server para Auth Service
resource "azurerm_postgresql_flexible_server" "auth" {
  name                   = "auth-db-server"
  resource_group_name    = azurerm_resource_group.main.name
  location               = var.db_location
  version                = "13"
  administrator_login    = "adminuser"
  administrator_password = var.postgres_auth_password != null ? var.postgres_auth_password : random_password.postgres_auth_password[0].result

  sku_name              = "B_Standard_B1ms"
  storage_mb            = 32768
  backup_retention_days = 7
  zone                  = "1"

  # Configuración de red simplificada
  delegated_subnet_id           = module.network.auth_subnet_id
  private_dns_zone_id           = azurerm_private_dns_zone.postgres.id
  public_network_access_enabled = false

  depends_on = [azurerm_private_dns_zone_virtual_network_link.postgres]
}

# Database para Auth Service
resource "azurerm_postgresql_flexible_server_database" "auth_db" {
  name      = "authdb"
  server_id = azurerm_postgresql_flexible_server.auth.id
  collation = "en_US.utf8"
  charset   = "utf8"
}

## Nota: Eliminado el recurso de base de datos para evitar fallo de esquema en el provider. La app usará DB_NAME estático.

# PostgreSQL Flexible Server para Users Service
resource "azurerm_postgresql_flexible_server" "users" {
  name                   = "users-db-server"
  resource_group_name    = azurerm_resource_group.main.name
  location               = var.db_location
  version                = "13"
  administrator_login    = "adminuser"
  administrator_password = var.postgres_users_password != null ? var.postgres_users_password : random_password.postgres_users_password[0].result

  sku_name              = "B_Standard_B1ms"
  storage_mb            = 32768
  backup_retention_days = 7
  zone                  = "1"

  # Configuración de red
  delegated_subnet_id           = module.network.users_subnet_id
  private_dns_zone_id           = azurerm_private_dns_zone.postgres.id
  public_network_access_enabled = false

  depends_on = [azurerm_private_dns_zone_virtual_network_link.postgres]
}

# Database para Users Service
resource "azurerm_postgresql_flexible_server_database" "users_db" {
  name      = "usersdb"
  server_id = azurerm_postgresql_flexible_server.users.id
  collation = "en_US.utf8"
  charset   = "utf8"
}

## Nota: Eliminado el recurso de base de datos; la app usará DB_NAME estático.

# PostgreSQL Flexible Server para Todos Service
resource "azurerm_postgresql_flexible_server" "todos" {
  name                   = "todos-db-server"
  resource_group_name    = azurerm_resource_group.main.name
  location               = var.db_location
  version                = "13"
  administrator_login    = "adminuser"
  administrator_password = var.postgres_todos_password != null ? var.postgres_todos_password : random_password.postgres_todos_password[0].result

  sku_name              = "B_Standard_B1ms"
  storage_mb            = 32768
  backup_retention_days = 7
  zone                  = "1"

  # Configuración de red
  delegated_subnet_id           = module.network.todos_subnet_id
  private_dns_zone_id           = azurerm_private_dns_zone.postgres.id
  public_network_access_enabled = false

  depends_on = [azurerm_private_dns_zone_virtual_network_link.postgres]
}

# Database para Todos Service
resource "azurerm_postgresql_flexible_server_database" "todos_db" {
  name      = "todosdb"
  server_id = azurerm_postgresql_flexible_server.todos.id
  collation = "en_US.utf8"
  charset   = "utf8"
}

## Nota: Eliminado el recurso de base de datos; la app usará DB_NAME estático.

# DNS Privado para PostgreSQL
resource "azurerm_private_dns_zone" "postgres" {
  name                = "privatelink.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "postgres" {
  name                  = "postgres-vnet-link"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.postgres.name
  virtual_network_id    = module.network.vnet_id
  registration_enabled  = true
}

# Manually create DNS records for existing PostgreSQL servers
resource "azurerm_private_dns_cname_record" "users_db" {
  name                = "users-db-server"
  zone_name           = azurerm_private_dns_zone.postgres.name
  resource_group_name = azurerm_resource_group.main.name
  ttl                 = 300
  record              = azurerm_postgresql_flexible_server.users.fqdn

  depends_on = [azurerm_postgresql_flexible_server.users]
}

resource "azurerm_private_dns_cname_record" "todos_db" {
  name                = "todos-db-server"
  zone_name           = azurerm_private_dns_zone.postgres.name
  resource_group_name = azurerm_resource_group.main.name
  ttl                 = 300
  record              = azurerm_postgresql_flexible_server.todos.fqdn

  depends_on = [azurerm_postgresql_flexible_server.todos]
}

resource "azurerm_private_dns_cname_record" "auth_db" {
  name                = "auth-db-server"
  zone_name           = azurerm_private_dns_zone.postgres.name
  resource_group_name = azurerm_resource_group.main.name
  ttl                 = 300
  record              = azurerm_postgresql_flexible_server.auth.fqdn

  depends_on = [azurerm_postgresql_flexible_server.auth]
}
