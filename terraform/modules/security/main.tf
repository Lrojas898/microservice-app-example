# Azure Cache for Redis
resource "azurerm_redis_cache" "main" {
  name                = "microservice-redis"
  location            = var.location
  resource_group_name = var.resource_group_name
  capacity            = 2
  family              = "C"
  sku_name            = "Standard"
  # non_ssl_port_enabled no es soportado en versiones recientes; se mantiene acceso SSL por defecto
  minimum_tls_version = "1.2"
}

# --- Redis Private Endpoint and DNS ---
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

# Application Gateway
resource "azurerm_application_gateway" "main" {
  name                = "microservice-appgw"
  resource_group_name = var.resource_group_name
  location            = var.location

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "appGatewayIpConfig"
    subnet_id = var.gateway_subnet_id
  }

  frontend_port {
    name = "http"
    port = 80
  }

  frontend_port {
    name = "users-port"
    port = 8083
  }

  frontend_port {
    name = "auth-port"
    port = 8000
  }

  frontend_port {
    name = "todos-port"
    port = 8082
  }

  frontend_ip_configuration {
    name                 = "public"
    public_ip_address_id = azurerm_public_ip.appgw.id
  }

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

  backend_http_settings {
    name                                = "users-settings"
    cookie_based_affinity               = "Disabled"
    port                                = 8083 # ← Puerto del users-service
    protocol                            = "Http"
    request_timeout                     = 30
    pick_host_name_from_backend_address = true
    probe_name                          = "users-probe"
  }

  backend_http_settings {
    name                                = "auth-settings"
    cookie_based_affinity               = "Disabled"
    port                                = 8000 # ← Puerto del auth-service
    protocol                            = "Http"
    request_timeout                     = 30
    pick_host_name_from_backend_address = true
    probe_name                          = "auth-probe"
  }

  backend_http_settings {
    name                                = "todos-settings"
    cookie_based_affinity               = "Disabled"
    port                                = 8082 # ← Puerto del todos-service
    protocol                            = "Http"
    request_timeout                     = 30
    pick_host_name_from_backend_address = true
    probe_name                          = "todos-probe"
  }

  probe {
    name                                      = "users-probe"
    protocol                                  = "Http"
    path                                      = "/users/health"
    interval                                  = 30
    timeout                                   = 30
    unhealthy_threshold                       = 3
    pick_host_name_from_backend_http_settings = true
  }

  probe {
    name                                      = "auth-probe"
    protocol                                  = "Http"
    path                                      = "/version"
    interval                                  = 30
    timeout                                   = 30
    unhealthy_threshold                       = 3
    pick_host_name_from_backend_http_settings = true
  }

  probe {
    name                                      = "todos-probe"
    protocol                                  = "Http"
    path                                      = "/health"
    interval                                  = 30
    timeout                                   = 30
    unhealthy_threshold                       = 3
    pick_host_name_from_backend_http_settings = true
  }

  request_routing_rule {
    name                       = "users-rule"
    rule_type                  = "Basic"
    http_listener_name         = "users-listener"
    backend_address_pool_name  = "users-pool"
    backend_http_settings_name = "users-settings"
    priority                   = 200 # ← Prioridad más alta que frontend-rule
  }

  request_routing_rule {
    name                       = "auth-rule"
    rule_type                  = "Basic"
    http_listener_name         = "auth-listener"
    backend_address_pool_name  = "auth-pool"
    backend_http_settings_name = "auth-settings"
    priority                   = 300 # ← Prioridad única
  }

  request_routing_rule {
    name                       = "todos-rule"
    rule_type                  = "Basic"
    http_listener_name         = "todos-listener"
    backend_address_pool_name  = "todos-pool"
    backend_http_settings_name = "todos-settings"
    priority                   = 400 # ← Prioridad única
  }

  backend_http_settings {
    name                                = "frontend-settings"
    cookie_based_affinity               = "Disabled"
    port                                = 80
    protocol                            = "Http"
    request_timeout                     = 30
    pick_host_name_from_backend_address = true

    # Health probe for frontend
    probe_name = "frontend-probe"
  }

  probe {
    name                                      = "frontend-probe"
    protocol                                  = "Http"
    path                                      = "/"
    interval                                  = 30
    timeout                                   = 30
    unhealthy_threshold                       = 3
    pick_host_name_from_backend_http_settings = true
  }

  http_listener {
    name                           = "frontend-listener"
    frontend_ip_configuration_name = "public"
    frontend_port_name             = "http"
    protocol                       = "Http"
  }

  http_listener {
    name                           = "users-listener"
    frontend_ip_configuration_name = "public"
    frontend_port_name             = "users-port"
    protocol                       = "Http"
  }

  http_listener {
    name                           = "auth-listener"
    frontend_ip_configuration_name = "public"
    frontend_port_name             = "auth-port"
    protocol                       = "Http"
  }

  http_listener {
    name                           = "todos-listener"
    frontend_ip_configuration_name = "public"
    frontend_port_name             = "todos-port"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "frontend-rule"
    rule_type                  = "Basic"
    http_listener_name         = "frontend-listener"
    backend_address_pool_name  = "frontend-pool"
    backend_http_settings_name = "frontend-settings"
    priority                   = 100
  }
}


# Log Processor (Logic App) - CORREGIDO
resource "azurerm_logic_app_workflow" "log_processor" {
  name                = "log-message-processor"
  location            = var.location
  resource_group_name = var.resource_group_name
  workflow_schema     = "https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#"
  workflow_version    = "1.0.0.0"
}
