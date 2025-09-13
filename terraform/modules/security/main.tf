# Configuración del proveedor Azure
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

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
  subnet_id           = var.cache_subnet_id
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
    subnet_id = var.gateway_subnet_id
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

  # Health Probes para cada servicio
  resource "azurerm_application_gateway_probe" "auth" {
    name                = "auth-probe"
    application_gateway_name = azurerm_application_gateway.main.name
    resource_group_name = var.resource_group_name
    protocol            = "Http"
    host                = "auth.example.com"
    path                = "/health"
    interval            = 30
    timeout             = 10
    unhealthy_threshold = 3
  }

  resource "azurerm_application_gateway_probe" "users" {
    name                = "users-probe"
    application_gateway_name = azurerm_application_gateway.main.name
    resource_group_name = var.resource_group_name
    protocol            = "Http"
    host                = "users.example.com"
    path                = "/health"
    interval            = 30
    timeout             = 10
    unhealthy_threshold = 3
  }

  resource "azurerm_application_gateway_probe" "todos" {
    name                = "todos-probe"
    application_gateway_name = azurerm_application_gateway.main.name
    resource_group_name = var.resource_group_name
    protocol            = "Http"
    host                = "todos.example.com"
    path                = "/health"
    interval            = 30
    timeout             = 10
    unhealthy_threshold = 3
  }

  # Backend HTTP Settings con timeouts ajustados
  backend_http_settings {
    name                  = "auth-settings"
    cookie_based_affinity = "Disabled"
    port                  = 8000
    protocol              = "Http"
    request_timeout       = 30
    probe_name            = "auth-probe"
  }

  backend_http_settings {
    name                  = "users-settings"
    cookie_based_affinity = "Disabled"
    port                  = 8083
    protocol              = "Http"
    request_timeout       = 45  # ¡CAMBIO IMPORTANTE! Aumentado de 30 a 45 segundos para manejar heterogeneidad de respuesta
    probe_name            = "users-probe"
  }

  backend_http_settings {
    name                  = "todos-settings"
    cookie_based_affinity = "Disabled"
    port                  = 8082
    protocol              = "Http"
    request_timeout       = 30
    probe_name            = "todos-probe"
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
}

# Public IP para el Application Gateway
resource "azurerm_public_ip" "appgw" {
  name                = "appgw-public-ip"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Application Insights para monitoreo
resource "azurerm_application_insights" "main" {
  name                = "microservice-appinsights"
  location            = var.location
  resource_group_name = var.resource_group_name
  application_type    = "web"
}

# Log Processor (Logic App)
resource "azurerm_logic_app_workflow" "log_processor" {
  name                = "log-message-processor"
  location            = var.location
  resource_group_name = var.resource_group_name

  definition = <<DEFINITION
{
  "$schema": "https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#",
  "actions": {
    "HTTP": {
      "inputs": {
        "body": "@triggerBody()",
        "method": "POST",
        "uri": "${azurerm_application_insights.main.instrumentation_key}"
      },
      "runAfter": {},
      "type": "Http"
    }
  },
  "contentVersion": "1.0.0.0",
  "outputs": {},
  "parameters": {},
  "triggers": {
    "manual": {
      "inputs": {
        "schema": {}
      },
      "kind": "Http",
      "type": "Request"
    }
  }
}
DEFINITION
}