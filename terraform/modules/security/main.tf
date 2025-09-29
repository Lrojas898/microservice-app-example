# Optimización de Costos: Application Gateway y Redis más económicos
# Ahorro estimado: ~40% en componentes de red y cache

# Azure Cache for Redis - Versión básica
resource "azurerm_redis_cache" "main" {
  name                          = "microservice-redis-optimized-${var.unique_suffix}"
  location                      = var.location
  resource_group_name           = var.resource_group_name
  capacity                      = 0       # Reducido de 2 a 0 (250MB)
  family                        = "C"     # Basic cache family
  sku_name                      = "Basic" # Cambiado de Standard a Basic
  minimum_tls_version           = "1.2"
  public_network_access_enabled = true # Habilitar acceso público para containers
}

# Private Endpoint temporalmente deshabilitado para evitar timeouts

# Firewall rule para permitir acceso completo a Redis
resource "azurerm_redis_firewall_rule" "allow_all" {
  name                = "allow_all_ips"
  redis_cache_name    = azurerm_redis_cache.main.name
  resource_group_name = var.resource_group_name
  start_ip            = "0.0.0.0"
  end_ip              = "255.255.255.255"
}

# Application Gateway removido - acceso directo a servicios
