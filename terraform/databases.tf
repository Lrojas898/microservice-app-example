
# Optimización de Costos: Bases de Datos Consolidadas
# Ahorro estimado: ~70% en costos de base de datos

# Generación de contraseña única para el servidor consolidado
resource "random_password" "postgres_consolidated_password" {
  length  = 16
  special = false
  upper   = true
  lower   = true
  numeric = true
}

# UN SOLO servidor PostgreSQL Flexible para todos los servicios
resource "azurerm_postgresql_flexible_server" "consolidated" {
  name                   = "microservice-db-server-${random_string.unique.result}"
  resource_group_name    = azurerm_resource_group.main.name
  location               = var.db_location
  version                = "13"
  administrator_login    = "adminuser"
  administrator_password = random_password.postgres_consolidated_password.result

  # SKU más pequeño para desarrollo/pruebas
  sku_name              = "B_Standard_B1ms"
  storage_mb            = 32768 # 32GB es el mínimo
  backup_retention_days = 7     # Mínimo para costos reducidos
  zone                  = "1"

  # Configuración de red - usar la subnet de users como principal
  delegated_subnet_id           = module.network.users_subnet_id
  private_dns_zone_id           = azurerm_private_dns_zone.postgres.id
  public_network_access_enabled = false

  depends_on = [azurerm_private_dns_zone_virtual_network_link.postgres]
}

# Bases de datos separadas en el mismo servidor
resource "azurerm_postgresql_flexible_server_database" "auth_db" {
  name      = "authdb"
  server_id = azurerm_postgresql_flexible_server.consolidated.id
  collation = "en_US.utf8"
  charset   = "utf8"
}

resource "azurerm_postgresql_flexible_server_database" "users_db" {
  name      = "usersdb"
  server_id = azurerm_postgresql_flexible_server.consolidated.id
  collation = "en_US.utf8"
  charset   = "utf8"
}

resource "azurerm_postgresql_flexible_server_database" "todos_db" {
  name      = "todosdb"
  server_id = azurerm_postgresql_flexible_server.consolidated.id
  collation = "en_US.utf8"
  charset   = "utf8"
}

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

# Registro DNS para el servidor consolidado
resource "azurerm_private_dns_cname_record" "consolidated_db" {
  name                = "microservice-db-server-${random_string.unique.result}"
  zone_name           = azurerm_private_dns_zone.postgres.name
  resource_group_name = azurerm_resource_group.main.name
  ttl                 = 300
  record              = azurerm_postgresql_flexible_server.consolidated.fqdn

  depends_on = [azurerm_postgresql_flexible_server.consolidated]
}


