#!/bin/bash

# Script de diagnóstico de conectividad para la infraestructura de microservicios
# Actualizado para arquitectura sin Application Gateway (acceso directo por IP pública)

set -e

RESOURCE_GROUP="microservice-app-rg"

echo "🔍 DIAGNÓSTICO DE CONECTIVIDAD DE MICROSERVICIOS"
echo "==============================================="
echo "📌 Arquitectura: Acceso directo por IPs públicas (sin Application Gateway)"
echo ""

echo "📋 1. Estado de Container Instances..."
echo "--------------------------------------"
az container list --resource-group "$RESOURCE_GROUP" \
    --query "[].{Name:name,State:containers[0].instanceView.currentState.state,RestartCount:containers[0].instanceView.restartCount,IP:ipAddress.ip,Ports:ipAddress.ports[].port}" \
    --output table 2>/dev/null || {
    echo "❌ Error al obtener Container Instances. Verifica que estén desplegados."
    echo ""
}

echo ""
echo "📋 2. IPs Públicas de los Servicios..."
echo "--------------------------------------"
echo "🔍 Obteniendo IPs públicas de cada servicio..."

AUTH_IP=$(az container show --name "auth-service" --resource-group "$RESOURCE_GROUP" --query "ipAddress.ip" -o tsv 2>/dev/null || echo "NO_ENCONTRADA")
USERS_IP=$(az container show --name "users-service" --resource-group "$RESOURCE_GROUP" --query "ipAddress.ip" -o tsv 2>/dev/null || echo "NO_ENCONTRADA")
TODOS_IP=$(az container show --name "todos-service" --resource-group "$RESOURCE_GROUP" --query "ipAddress.ip" -o tsv 2>/dev/null || echo "NO_ENCONTRADA")
FRONTEND_IP=$(az container show --name "frontend-service" --resource-group "$RESOURCE_GROUP" --query "ipAddress.ip" -o tsv 2>/dev/null || echo "NO_ENCONTRADA")

echo "🌐 Auth Service:     $AUTH_IP:8000"
echo "🌐 Users Service:    $USERS_IP:8083"
echo "🌐 Todos Service:    $TODOS_IP:8082"
echo "🌐 Frontend Service: $FRONTEND_IP:80"

echo ""
echo "📋 3. Verificación de Conectividad Externa..."
echo "---------------------------------------------"

check_endpoint() {
    local name=$1
    local url=$2
    local expected_status=${3:-200}

    echo -n "🔍 Verificando $name... "

    if response=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 10 "$url" 2>/dev/null); then
        if [ "$response" = "$expected_status" ]; then
            echo "✅ OK ($response)"
            return 0
        else
            echo "❌ FAIL ($response, esperado $expected_status)"
            return 1
        fi
    else
        echo "❌ FAIL (sin respuesta)"
        return 1
    fi
}

if [ "$FRONTEND_IP" != "NO_ENCONTRADA" ]; then
    check_endpoint "Frontend" "http://$FRONTEND_IP/"
else
    echo "❌ Frontend no disponible - IP no encontrada"
fi

if [ "$AUTH_IP" != "NO_ENCONTRADA" ]; then
    check_endpoint "Auth API" "http://$AUTH_IP:8000/version"
else
    echo "❌ Auth Service no disponible - IP no encontrada"
fi

if [ "$USERS_IP" != "NO_ENCONTRADA" ]; then
    check_endpoint "Users API" "http://$USERS_IP:8083/health"
else
    echo "❌ Users Service no disponible - IP no encontrada"
fi

if [ "$TODOS_IP" != "NO_ENCONTRADA" ]; then
    check_endpoint "Todos API" "http://$TODOS_IP:8082/health"
else
    echo "❌ Todos Service no disponible - IP no encontrada"
fi

echo ""
echo "📋 4. Estado de la Red Virtual..."
echo "---------------------------------"
az network vnet show --name "microservice-vnet" --resource-group "$RESOURCE_GROUP" \
    --query "{name:name,provisioningState:provisioningState,addressSpace:addressSpace}" \
    --output table 2>/dev/null || {
    echo "❌ Error al obtener información de la VNet."
    echo ""
}

echo ""
echo "📋 5. Subnets Activas (solo DB y Cache)..."
echo "------------------------------------------"
az network vnet subnet list --vnet-name "microservice-vnet" --resource-group "$RESOURCE_GROUP" \
    --query "[].{Name:name,AddressPrefix:addressPrefix,ProvisioningState:provisioningState}" \
    --output table 2>/dev/null || {
    echo "❌ Error al obtener información de las subnets."
    echo ""
}

echo ""
echo "📋 6. Estado de PostgreSQL y Redis..."
echo "-------------------------------------"
echo "🔍 PostgreSQL Flexible Server..."
az postgres flexible-server list --resource-group "$RESOURCE_GROUP" \
    --query "[].{Name:name,State:state,FQDN:fullyQualifiedDomainName}" \
    --output table 2>/dev/null || {
    echo "❌ Error al obtener información de PostgreSQL."
}

echo ""
echo "🔍 Redis Cache..."
az redis list --resource-group "$RESOURCE_GROUP" \
    --query "[].{Name:name,ProvisioningState:provisioningState,RedisVersion:redisVersion,HostName:hostName}" \
    --output table 2>/dev/null || {
    echo "❌ Error al obtener información de Redis."
}

echo ""
echo "💡 RECOMENDACIONES:"
echo "==================="
echo "1. ✅ Verificar que todos los Container Instances tengan IPs públicas asignadas"
echo "2. ✅ Comprobar que los servicios respondan en sus puertos específicos"
echo "3. ✅ Verificar que PostgreSQL y Redis estén accesibles desde los contenedores"
echo "4. ❌ Ya NO hay Application Gateway - acceso directo por IP pública"
echo "5. 🔧 Si los contenedores no están desplegados, ejecutar 'terraform apply'"

echo ""
echo "🔧 Comandos útiles para debugging:"
echo "----------------------------------"
echo "# Ver logs de un contenedor específico:"
echo "az container logs --name [auth-service|users-service|todos-service|frontend-service] --resource-group $RESOURCE_GROUP"
echo ""
echo "# Reiniciar un contenedor:"
echo "az container restart --name [container-name] --resource-group $RESOURCE_GROUP"
echo ""
echo "# Ver todas las IPs públicas:"
echo "az container list --resource-group $RESOURCE_GROUP --query '[].{Name:name,IP:ipAddress.ip}' --output table"
echo ""
echo "# Verificar conectividad manual:"
echo "curl -v http://[IP]:[PORT]/[ENDPOINT]"

echo ""
echo "✨ Diagnóstico de conectividad completado!"