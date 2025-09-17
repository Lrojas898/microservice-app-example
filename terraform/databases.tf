# PostgreSQL Flexible Server para Auth Service
resource "azurerm_postgresql_flexible_server" "auth" {
  name                   = "auth-db-server"
  resource_group_name    = var.resource_group_name
  location               = var.location
  version                = "12"
  administrator_login    = "adminuser"
  administrator_password = var.postgres_auth_password != null ? var.postgres_auth_password : random_password.postgres_auth_password[0].result

  sku_name    = "B_Standard_B1ms"
  storage_mb  = 32768
  backup_retention_days = 7
  zone        = "1"
}

## Nota: Eliminado el recurso de base de datos para evitar fallo de esquema en el provider. La app usará DB_NAME estático.

# PostgreSQL Flexible Server para Users Service
resource "azurerm_postgresql_flexible_server" "users" {
  name                   = "users-db-server"
  resource_group_name    = var.resource_group_name
  location               = var.location
  version                = "12"
  administrator_login    = "adminuser"
  administrator_password = var.postgres_users_password != null ? var.postgres_users_password : random_password.postgres_users_password[0].result

  sku_name    = "B_Standard_B1ms"
  storage_mb  = 32768
  backup_retention_days = 7
  zone        = "1"
}

## Nota: Eliminado el recurso de base de datos; la app usará DB_NAME estático.

# PostgreSQL Flexible Server para Todos Service
resource "azurerm_postgresql_flexible_server" "todos" {
  name                   = "todos-db-server"
  resource_group_name    = var.resource_group_name
  location               = var.location
  version                = "12"
  administrator_login    = "adminuser"
  administrator_password = var.postgres_todos_password != null ? var.postgres_todos_password : random_password.postgres_todos_password[0].result

  sku_name    = "B_Standard_B1ms"
  storage_mb  = 32768
  backup_retention_days = 7
  zone        = "1"
}

## Nota: Eliminado el recurso de base de datos; la app usará DB_NAME estático.