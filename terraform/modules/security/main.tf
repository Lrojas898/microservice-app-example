# Optimización de Costos: Application Gateway y Redis más económicos
# Ahorro estimado: ~40% en componentes de red y cache

# Azure Cache for Redis - Versión básica
resource "azurerm_redis_cache" "main" {
  name                = "microservice-redis-optimized-${var.unique_suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  capacity            = 0       # Reducido de 2 a 0 (250MB)
  family              = "C"     # Basic cache family
  sku_name            = "Basic" # Cambiado de Standard a Basic
  minimum_tls_version = "1.2"
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

# Public IP para el Application Gateway
resource "azurerm_public_ip" "appgw" {
  name                = "appgw-public-ip"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Application Gateway - CORREGIDO con Path-Based Routing
resource "azurerm_application_gateway" "main" {
  name                = "microservice-appgw"
  resource_group_name = var.resource_group_name
  location            = var.location

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 1 # Reducido de 2 a 1 instancia
  }

  gateway_ip_configuration {
    name      = "appGatewayIpConfig"
    subnet_id = var.gateway_subnet_id
  }

  # SOLO puerto 80 necesario para path-based routing
  frontend_port {
    name = "http"
    port = 80
  }

  frontend_ip_configuration {
    name                 = "public"
    public_ip_address_id = azurerm_public_ip.appgw.id
  }

  # Backend pools (sin cambios)
  backend_address_pool {
    name         = "frontend-pool"
    ip_addresses = [var.frontend_container_ip]
  }

  backend_address_pool {
    name         = "users-pool"
    ip_addresses = [var.users_container_ip]
  }

  backend_address_pool {
    name         = "auth-pool"
    ip_addresses = [var.auth_container_ip]
  }

  backend_address_pool {
    name         = "todos-pool"
    ip_addresses = [var.todos_container_ip]
  }

  # Backend HTTP settings (sin cambios)
  backend_http_settings {
    name                                = "users-settings"
    cookie_based_affinity               = "Disabled"
    port                                = 8083
    protocol                            = "Http"
    request_timeout                     = 30
    pick_host_name_from_backend_address = true
    probe_name                          = "users-probe"
  }

  backend_http_settings {
    name                                = "auth-settings"
    cookie_based_affinity               = "Disabled"
    port                                = 8000
    protocol                            = "Http"
    request_timeout                     = 30
    pick_host_name_from_backend_address = true
    probe_name                          = "auth-probe"
  }

  backend_http_settings {
    name                                = "todos-settings"
    cookie_based_affinity               = "Disabled"
    port                                = 8082
    protocol                            = "Http"
    request_timeout                     = 30
    pick_host_name_from_backend_address = true
    probe_name                          = "todos-probe"
  }

  backend_http_settings {
    name                                = "frontend-settings"
    cookie_based_affinity               = "Disabled"
    port                                = 80
    protocol                            = "Http"
    request_timeout                     = 30
    pick_host_name_from_backend_address = true
    probe_name                          = "frontend-probe"
  }

  # Health probes (sin cambios)
  probe {
    name                                      = "users-probe"
    protocol                                  = "Http"
    path                                      = "/users/health"
    interval                                  = 60
    timeout                                   = 30
    unhealthy_threshold                       = 3
    pick_host_name_from_backend_http_settings = true
  }

  probe {
    name                                      = "auth-probe"
    protocol                                  = "Http"
    path                                      = "/version"
    interval                                  = 60
    timeout                                   = 30
    unhealthy_threshold                       = 3
    pick_host_name_from_backend_http_settings = true
  }

  probe {
    name                                      = "todos-probe"
    protocol                                  = "Http"
    path                                      = "/health"
    interval                                  = 60
    timeout                                   = 30
    unhealthy_threshold                       = 3
    pick_host_name_from_backend_http_settings = true
  }

  probe {
    name                                      = "frontend-probe"
    protocol                                  = "Http"
    path                                      = "/"
    interval                                  = 60
    timeout                                   = 30
    unhealthy_threshold                       = 3
    pick_host_name_from_backend_http_settings = true
  }

  # UN SOLO LISTENER en puerto 80
  http_listener {
    name                           = "main-listener"
    frontend_ip_configuration_name = "public"
    frontend_port_name             = "http"
    protocol                       = "Http"
  }

  # URL Path Map - NUEVA CONFIGURACION para routing por ruta
  url_path_map {
    name                               = "main-path-map"
    default_backend_address_pool_name  = "frontend-pool"
    default_backend_http_settings_name = "frontend-settings"

    # Rutas para Auth Service
    path_rule {
      name                       = "auth-paths"
      paths                      = ["/login*", "/api/auth*", "/version*"]
      backend_address_pool_name  = "auth-pool"
      backend_http_settings_name = "auth-settings"
    }

    # Rutas para Users Service
    path_rule {
      name                       = "users-paths"  
      paths                      = ["/api/users*", "/users*"]
      backend_address_pool_name  = "users-pool"
      backend_http_settings_name = "users-settings"
    }

    # Rutas para Todos Service  
    path_rule {
      name                       = "todos-paths"
      paths                      = ["/todos*", "/api/todos*"]
      backend_address_pool_name  = "todos-pool" 
      backend_http_settings_name = "todos-settings"
    }
  }

  # UNA SOLA REGLA con PathBasedRouting
  request_routing_rule {
    name                       = "main-routing-rule"
    rule_type                  = "PathBasedRouting"  # CAMBIO CRÍTICO
    http_listener_name         = "main-listener"
    url_path_map_name          = "main-path-map"
    priority                   = 100
  }
}

# Log Processor simplificado (Logic App básico)
resource "azurerm_logic_app_workflow" "log_processor" {
  name                = "log-message-processor"
  location            = var.location
  resource_group_name = var.resource_group_name
  workflow_schema     = "https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#"
  workflow_version    = "1.0.0.0"
}
