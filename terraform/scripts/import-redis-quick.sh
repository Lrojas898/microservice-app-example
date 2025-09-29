#!/bin/bash

# Script rápido para importar el Redis Cache existente
# Usando el ID exacto corregido basado en el error de Terraform

set -e

echo "📦 Importando Redis Cache existente..."

# ID correcto con "redis" en minúsculas (según el formato esperado por Terraform)
REDIS_ID="/subscriptions/eba0e2cc-47c4-4522-9928-a3f676b3e9e2/resourceGroups/microservice-app-rg/providers/Microsoft.Cache/redis/microservice-redis-rjw97jf6"

echo "🗃️  Importando Redis Cache con ID: $REDIS_ID"
echo ""

terraform import module.security.azurerm_redis_cache.main "$REDIS_ID"

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Redis Cache importado exitosamente!"
    echo ""
    echo "🔄 Próximos pasos:"
    echo "   1. terraform plan   # Para verificar diferencias"
    echo "   2. terraform apply  # Para desplegar la infraestructura optimizada"
    echo ""
    echo "💡 El Redis Cache existente ahora está bajo gestión de Terraform"
else
    echo ""
    echo "❌ Error al importar Redis Cache"
    echo "💡 Revisa el output anterior para más detalles"
    exit 1
fi