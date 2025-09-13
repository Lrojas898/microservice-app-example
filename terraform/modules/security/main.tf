# Azure Cache for Redis (para Cache-Aside y cola de mensajes)
resource "azurerm_redis_cache" "main" {
  name                = "microservice-redis"
  location            = var.location
  resource_group_name = var.resource_group_name
  capacity            = 2
  family              = "C"
  sku_name            = "Standard"
  enable_non_ssl_port = false
  minimum_tls_version = "1.2"
  subnet_id           = module.network.cache_subnet_id
}

# Application Gateway (punto de entrada unificado)
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
    subnet_id = module.network.gateway_subnet_id
  }

  frontend_port {
    name = "http"
    port = 80
  }

  frontend_ip_configuration {
    name                 = "public"
    public_ip_address_id = azurerm_public_ip.appgw.id
  }

  backend_address_pool {
    name = "auth-pool"
  }

  backend_address_pool {
    name = "users-pool"
  }

  backend_address_pool {
    name = "todos-pool"
  }

  backend_http_settings {
    name                  = "auth-settings"
    cookie_based_affinity = "Disabled"
    port                  = 3000
    protocol              = "Http"
    request_timeout       = 30
  }

  backend_http_settings {
    name                  = "users-settings"
    cookie_based_affinity = "Disabled"
    port                  = 8080
    protocol              = "Http"
    request_timeout       = 30
  }

  backend_http_settings {
    name                  = "todos-settings"
    cookie_based_affinity = "Disabled"
    port                  = 4000
    protocol              = "Http"
    request_timeout       = 30
  }

  http_listener {
    name                           = "auth-listener"
    frontend_ip_configuration_name = "public"
    frontend_port_name             = "http"
    protocol                       = "Http"
    host_name                      = "auth.example.com"
  }

  http_listener {
    name                           = "users-listener"
    frontend_ip_configuration_name = "public"
    frontend_port_name             = "http"
    protocol                       = "Http"
    host_name                      = "users.example.com"
  }

  http_listener {
    name                           = "todos-listener"
    frontend_ip_configuration_name = "public"
    frontend_port_name             = "http"
    protocol                       = "Http"
    host_name                      = "todos.example.com"
  }

  request_routing_rule {
    name                       = "auth-rule"
    rule_type                  = "Basic"
    http_listener_name         = "auth-listener"
    backend_address_pool_name  = "auth-pool"
    backend_http_settings_name = "auth-settings"
  }

  request_routing_rule {
    name                       = "users-rule"
    rule_type                  = "Basic"
    http_listener_name         = "users-listener"
    backend_address_pool_name  = "users-pool"
    backend_http_settings_name = "users-settings"
  }

  request_routing_rule {
    name                       = "todos-rule"
    rule_type                  = "Basic"
    http_listener_name         = "todos-listener"
    backend_address_pool_name  = "todos-pool"
    backend_http_settings_name = "todos-settings"
  }

  # Public IP para el Application Gateway
  resource "azurerm_public_ip" "appgw" {
    name                = "appgw-public-ip"
    resource_group_name = var.resource_group_name
    location            = var.location
    allocation_method   = "Static"
    sku                 = "Standard"
  }
}