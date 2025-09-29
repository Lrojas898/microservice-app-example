#!/bin/bash

# Script para limpiar recursos existentes conflictivos
# ⚠️  CUIDADO: Esto eliminará recursos existentes en Azure

set -e

echo "🧹 Script de limpieza de recursos existentes"
echo ""
echo "⚠️  ADVERTENCIA: Esto eliminará recursos reales de Azure"
echo "Solo úsalo si estás seguro de que quieres eliminar:"
echo "  - Redis Cache: microservice-redis-rjw97jf6"
echo "  - Otros recursos conflictivos"
echo ""

read -p "¿Continuar con la eliminación? (y/N): " confirm

if [[ $confirm =~ ^[Yy]$ ]]; then
    echo "🗑️  Eliminando Redis Cache existente..."
    
    # Eliminar Redis Cache
    az redis delete \
        --name microservice-redis-rjw97jf6 \
        --resource-group microservice-app-rg \
        --yes
    
    if [ $? -eq 0 ]; then
        echo "✅ Redis Cache eliminado"
    else
        echo "❌ Error al eliminar Redis Cache"
    fi
    
    echo ""
    echo "⏳ Esperando propagación de cambios..."
    sleep 30
    
    echo "✅ Limpieza completada!"
    echo ""
    echo "🔄 Ahora puedes ejecutar:"
    echo "   terraform plan"
    echo "   terraform apply"
    
else
    echo "❌ Operación cancelada"
    echo ""
    echo "💡 Alternativas:"
    echo "   1. Usar script de importación: ./import-existing-resources.sh"
    echo "   2. Cambiar nombres en la configuración"
fi