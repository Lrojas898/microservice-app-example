#!/bin/bash

# Script de emergencia para corregir auth container bloqueado

set -e

echo "🚨 Reparando auth container bloqueado..."

# 1. Cancelar el deploy actual si está colgado
echo "⏹️ Cancelando deploy colgado..."
pkill -f "terraform apply" || true

# 2. Ver estado actual y logs
echo "🔍 Diagnóstico del auth container..."
echo "Estado actual:"
az container show --name auth-service --resource-group microservice-app-rg --query "containers[0].instanceView.currentState" 2>/dev/null || echo "Container no existe aún"

echo ""
echo "Últimos logs:"
az container logs --name auth-service --resource-group microservice-app-rg --tail 20 2>/dev/null || echo "No hay logs disponibles"

# 3. Verificar dependencias críticas
echo ""
echo "🔍 Verificando dependencias..."

echo "PostgreSQL:"
az postgres flexible-server show --name postgres-consolidated-* --resource-group microservice-app-rg --query "state" 2>/dev/null || echo "❌ PostgreSQL no encontrado"

echo "Redis:"
az redis show --name microservice-redis-optimized-* --resource-group microservice-app-rg --query "provisioningState" 2>/dev/null || echo "❌ Redis no encontrado"

echo "Users Service:"
az container show --name users-service --resource-group microservice-app-rg --query "containers[0].instanceView.currentState.state" 2>/dev/null || echo "❌ Users service no encontrado"

echo "Zipkin VM:"
az vm show --name zipkin-vm --resource-group microservice-app-rg --query "powerState" 2>/dev/null || echo "❌ Zipkin VM no encontrado"

# 4. Solución rápida: Deploy auth con configuración mínima
echo ""
echo "🔧 Aplicando configuración corregida..."

# Crear configuración temporal del auth service sin dependencias problemáticas
cat > /tmp/auth-minimal.tf << 'EOF'
resource "azurerm_container_group" "auth_minimal" {
  name                = "auth-service-minimal"
  location            = var.location
  resource_group_name = var.resource_group_name
  ip_address_type     = "Public"
  os_type             = "Linux"

  container {
    name   = "auth-container"
    image  = var.auth_api_image
    cpu    = "0.25"
    memory = "0.5"

    ports {
      port     = 8000
      protocol = "TCP"
    }

    environment_variables = {
      AUTH_API_PORT = "8000"
      JWT_SECRET    = "myfancysecret1234567890abcdef1234"
      # URLs mínimas para que arranque
      USERS_API_ADDRESS = "http://localhost:8083"  # Placeholder
      # DB y Redis opcionales para startup inicial
      DB_HOST = "localhost"
      DB_NAME = "authdb"
      DB_USER = "postgres"
      DB_PASSWORD = "postgres"
      DB_PORT = "5432"
    }
  }

  image_registry_credential {
    server   = "index.docker.io"
    username = var.dockerhub_username
    password = var.dockerhub_token
  }

  depends_on = [
    azurerm_resource_group.main
  ]
}
EOF

echo "✅ Configuración de emergencia lista"
echo ""
echo "🔧 Opciones de recuperación:"
echo "1. Destruir auth actual: terraform destroy -target=azurerm_container_group.auth"
echo "2. Deploy mínimo: terraform apply usando /tmp/auth-minimal.tf"
echo "3. Deploy conservador: ./conservative-deploy.sh"
echo "4. Restart completo: terraform destroy && terraform apply"
echo ""
echo "💡 Recomendación: Ejecutar conservative-deploy.sh para deploy paso a paso"