# ALTERNATIVA ULTRA-RÁPIDA: Zipkin Slim optimizado
# Úsala si el problema persiste con la configuración principal

resource "azurerm_container_group" "zipkin_optimized" {
  name                = "zipkin-service-optimized"
  location            = var.location
  resource_group_name = var.resource_group_name
  ip_address_type     = "Public"
  os_type             = "Linux"

  container {
    name   = "zipkin-container"
    image  = "openzipkin/zipkin-slim:latest" # IMAGEN MÁS LIVIANA
    cpu    = "1.0"
    memory = "2.0"

    ports {
      port     = 9411
      protocol = "TCP"
    }

    environment_variables = {
      STORAGE_TYPE = "mem"
      # JVM OPTIMIZADO para startup súper rápido
      JAVA_OPTS = "-Xms512m -Xmx1024m -XX:+UseSerialGC -Djava.security.egd=file:/dev/./urandom -XX:TieredStopAtLevel=1"
      # Configuraciones adicionales para Azure
      SELF_TRACING_ENABLED = "false"
      QUERY_ENABLED        = "true"
      SEARCH_ENABLED       = "true"
      # Reducir logs para startup más rápido
      LOGGING_LEVEL_ROOT = "WARN"
    }

    # Health check optimizado
    liveness_probe {
      http_get {
        path   = "/health"
        port   = 9411
        scheme = "Http"
      }
      initial_delay_seconds = 30 # Reducido de default
      period_seconds        = 10
      timeout_seconds       = 5
      failure_threshold     = 3
    }

    readiness_probe {
      http_get {
        path   = "/health"
        port   = 9411
        scheme = "Http"
      }
      initial_delay_seconds = 15 # Startup más rápido
      period_seconds        = 5
      timeout_seconds       = 3
      failure_threshold     = 3
    }
  }

  # Restart policy optimizada
  restart_policy = "Always"

  tags = {
    Environment = "production"
    Service     = "zipkin-optimized"
    Performance = "fast-startup"
  }

  depends_on = [
    azurerm_resource_group.main
  ]
}

# Output para usar la IP optimizada
output "zipkin_optimized_ip" {
  description = "Public IP of optimized Zipkin service"
  value       = azurerm_container_group.zipkin_optimized.ip_address
}