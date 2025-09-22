#!/bin/bash

# Script para importar recursos existentes de Azure al estado de Terraform
# Esto evita conflictos cuando los recursos ya existen en Azure

set -e

echo "📦 Importando recursos existentes de Azure..."

# Primero obtenemos la información del Redis Cache para construir el ID correcto
REDIS_NAME="microservice-redis-rjw97jf6"
RESOURCE_GROUP="microservice-app-rg"

echo "🔍 Obteniendo ID del recurso Redis Cache..."

# Obtener el ID completo del recurso usando Azure CLI
REDIS_ID_RAW=$(az redis show --name "$REDIS_NAME" --resource-group "$RESOURCE_GROUP" --query "id" -o tsv 2>/dev/null)

if [ -z "$REDIS_ID_RAW" ]; then
    echo "❌ No se pudo encontrar el Redis Cache $REDIS_NAME"
    echo "💡 Verifica que el nombre y resource group sean correctos:"
    echo "   - Redis Name: $REDIS_NAME"
    echo "   - Resource Group: $RESOURCE_GROUP"
    exit 1
fi

# Normalizar el ID - Azure CLI a veces devuelve "Redis" pero Terraform espera "redis"
REDIS_ID=$(echo "$REDIS_ID_RAW" | sed 's|/Microsoft.Cache/Redis/|/Microsoft.Cache/redis/|')

echo "✅ Redis ID encontrado: $REDIS_ID_RAW"
echo "✅ Redis ID normalizado: $REDIS_ID"
echo ""

echo "🗃️  Importando Redis Cache al estado de Terraform..."
terraform import module.security.azurerm_redis_cache.main "$REDIS_ID"

if [ $? -eq 0 ]; then
    echo "✅ Redis Cache importado exitosamente"
else
    echo "❌ Error al importar Redis Cache"
    echo "💡 Posibles causas:"
    echo "   1. El recurso ya está en el estado de Terraform"
    echo "   2. El módulo/recurso no existe en la configuración"
    echo "   3. Problemas de permisos"
    exit 1
fi

echo ""
echo "🔍 Verificando otros recursos que puedan necesitar importación..."

# Aquí puedes agregar otros recursos si es necesario
# echo "Checking for other resources..."
# az resource list --resource-group "$RESOURCE_GROUP" --query "[].{Name:name, Type:type}" -o table

echo ""
echo "✅ Importación completada!"
echo ""
echo "🔄 Próximos pasos:"
echo "   1. terraform plan   # Para verificar diferencias"
echo "   2. terraform apply  # Para sincronizar estado"

echo ""
echo "💡 Nota: Después de importar, Terraform manejará este recurso existente"
echo "Si hay diferencias en la configuración, Terraform las mostrará en el plan"