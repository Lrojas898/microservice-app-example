# PostgreSQL para Auth Service
resource "azurerm_postgresql_server" "auth" {
  name                = "auth-db-server"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku_name            = "B_Gen5_1"
  storage_mb          = 5120
  backup_retention_days = 7
  geo_redundant_backup_enabled = false
  auto_grow_enabled          = true
  administrator_login        = "adminuser"
  administrator_login_password = var.postgres_auth_password != null ? var.postgres_auth_password : random_password.postgres_auth_password[0].result
  version                    = "11"
  ssl_enforcement_enabled    = true
}

resource "azurerm_postgresql_database" "auth" {
  name                = "authdb"
  resource_group_name = var.resource_group_name
  server_name         = azurerm_postgresql_server.auth.name
  charset             = "UTF8"
  collation           = "English_United States.1252"
}

# PostgreSQL para Users Service
resource "azurerm_postgresql_server" "users" {
  name                = "users-db-server"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku_name            = "B_Gen5_1"
  storage_mb          = 5120
  backup_retention_days = 7
  geo_redundant_backup_enabled = false
  auto_grow_enabled          = true
  administrator_login        = "adminuser"
  administrator_login_password = var.postgres_users_password != null ? var.postgres_users_password : random_password.postgres_users_password[0].result
  version                    = "11"
  ssl_enforcement_enabled    = true
}

resource "azurerm_postgresql_database" "users" {
  name                = "usersdb"
  resource_group_name = var.resource_group_name
  server_name         = azurerm_postgresql_server.users.name
  charset             = "UTF8"
  collation           = "English_United States.1252"
}

# PostgreSQL para Todos Service
resource "azurerm_postgresql_server" "todos" {
  name                = "todos-db-server"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku_name            = "B_Gen5_1"
  storage_mb          = 5120
  backup_retention_days = 7
  geo_redundant_backup_enabled = false
  auto_grow_enabled          = true
  administrator_login        = "adminuser"
  administrator_login_password = var.postgres_todos_password != null ? var.postgres_todos_password : random_password.postgres_todos_password[0].result
  version                    = "11"
  ssl_enforcement_enabled    = true
}

resource "azurerm_postgresql_database" "todos" {
  name                = "todosdb"
  resource_group_name = var.resource_group_name
  server_name         = azurerm_postgresql_server.todos.name
  charset             = "UTF8"
  collation           = "English_United States.1252"
}