#!/bin/bash

# Script de diagnóstico de conectividad para la infraestructura de microservicios
# Ayuda a identificar problemas de red y contenedores

set -e

RESOURCE_GROUP="microservice-app-rg"
APPGW_NAME="microservice-appgw"

echo "🔍 DIAGNÓSTICO DE CONECTIVIDAD DE MICROSERVICIOS"
echo "=============================================="
echo ""

echo "📋 1. Estado de Container Instances..."
echo "--------------------------------------"
az container list --resource-group "$RESOURCE_GROUP" --output table 2>/dev/null || {
    echo "❌ Error al obtener Container Instances. Verifica que estén desplegados."
    echo ""
}

echo ""
echo "📋 2. Estado del Application Gateway..."
echo "---------------------------------------"
az network application-gateway show --name "$APPGW_NAME" --resource-group "$RESOURCE_GROUP" \
    --query "{name:name,operationalState:operationalState,provisioningState:provisioningState}" \
    --output table 2>/dev/null || {
    echo "❌ Error al obtener Application Gateway. Verifica que esté desplegado."
    echo ""
}

echo ""
echo "📋 3. Backend Pools del Application Gateway..."
echo "----------------------------------------------"
az network application-gateway address-pool list \
    --gateway-name "$APPGW_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --output table 2>/dev/null || {
    echo "❌ Error al obtener backend pools."
    echo ""
}

echo ""
echo "📋 4. Health Probes del Application Gateway..."
echo "----------------------------------------------"
az network application-gateway probe list \
    --gateway-name "$APPGW_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --output table 2>/dev/null || {
    echo "❌ Error al obtener health probes."
    echo ""
}

echo ""
echo "📋 5. Estado de la Red Virtual..."
echo "---------------------------------"
az network vnet show --name "microservice-vnet" --resource-group "$RESOURCE_GROUP" \
    --query "{name:name,provisioningState:provisioningState,addressSpace:addressSpace}" \
    --output table 2>/dev/null || {
    echo "❌ Error al obtener información de la VNet."
    echo ""
}

echo ""
echo "📋 6. Subnets de la Red Virtual..."
echo "----------------------------------"
az network vnet subnet list --vnet-name "microservice-vnet" --resource-group "$RESOURCE_GROUP" \
    --query "[].{Name:name,AddressPrefix:addressPrefix,ProvisioningState:provisioningState}" \
    --output table 2>/dev/null || {
    echo "❌ Error al obtener información de las subnets."
    echo ""
}

echo ""
echo "📋 7. Verificando conectividad específica..."
echo "--------------------------------------------"
TARGET_IP="10.0.7.4"
echo "🎯 Destino problemático: $TARGET_IP"
echo "📍 Subnet esperada: users-container-subnet (10.0.7.0/24)"

# Intentar encontrar qué recurso tiene esa IP
echo ""
echo "🔍 Buscando recursos con IP $TARGET_IP..."
az network nic list --resource-group "$RESOURCE_GROUP" \
    --query "[?ipConfigurations[0].privateIPAddress=='$TARGET_IP'].{Name:name,IP:ipConfigurations[0].privateIPAddress,Subnet:ipConfigurations[0].subnet.id}" \
    --output table 2>/dev/null || {
    echo "ℹ️  No se encontraron NICs con esa IP específica."
}

echo ""
echo "💡 RECOMENDACIONES:"
echo "==================="
echo "1. Verificar que los Container Instances estén en estado 'Running'"
echo "2. Comprobar que el Application Gateway tenga backend pools configurados correctamente"
echo "3. Verificar que las health probes estén pasando"
echo "4. Si los contenedores no están desplegados, ejecutar 'terraform apply'"
echo "5. Revisar logs de los contenedores si están desplegados pero no responden"
echo ""
echo "🔧 Comandos útiles adicionales:"
echo "------------------------------"
echo "# Ver logs de un contenedor específico:"
echo "az container logs --name [container-name] --resource-group $RESOURCE_GROUP"
echo ""
echo "# Reiniciar un contenedor:"
echo "az container restart --name [container-name] --resource-group $RESOURCE_GROUP"
echo ""
echo "# Ver detalles de health del Application Gateway:"
echo "az network application-gateway show-backend-health --name $APPGW_NAME --resource-group $RESOURCE_GROUP"