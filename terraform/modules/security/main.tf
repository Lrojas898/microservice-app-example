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
  public_network_access_enabled = true    # Habilitar acceso público para containers
}

# --- Redis Private Endpoint and DNS (Mantener para seguridad) ---
resource "azurerm_private_endpoint" "redis" {
  name                = "redis-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.cache_subnet_id

  private_service_connection {
    name                           = "redis-privatesc"
    private_connection_resource_id = azurerm_redis_cache.main.id
    subresource_names              = ["redisCache"]
    is_manual_connection           = false
  }
}

resource "azurerm_private_dns_zone" "redis" {
  name                = "privatelink.redis.cache.windows.net"
  resource_group_name = var.resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "redis" {
  name                  = "redis-dns-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.redis.name
  virtual_network_id    = var.vnet_id
}

resource "azurerm_private_dns_a_record" "redis" {
  name                = azurerm_redis_cache.main.name
  zone_name           = azurerm_private_dns_zone.redis.name
  resource_group_name = var.resource_group_name
  ttl                 = 300
  records             = [azurerm_private_endpoint.redis.private_service_connection[0].private_ip_address]
}

# Application Gateway removido - acceso directo a servicios
