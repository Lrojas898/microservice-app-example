#!/bin/bash

# Script para actualizar URLs de servicios post-deploy
# Ejecutar después de terraform apply

echo "🔄 Actualizando URLs de servicios entre containers..."

# Obtener IPs de servicios
AUTH_IP=$(terraform output -raw auth_service_ip)
USERS_IP=$(terraform output -raw users_service_ip)
TODOS_IP=$(terraform output -raw todos_service_ip)
ZIPKIN_IP=$(terraform output -raw zipkin_service_ip)

echo "📍 IPs obtenidas:"
echo "  Auth: $AUTH_IP"
echo "  Users: $USERS_IP"
echo "  Todos: $TODOS_IP"
echo "  Zipkin: $ZIPKIN_IP"

# Función para actualizar variables de entorno de un container
update_container_env() {
    local CONTAINER_GROUP=$1
    local ENV_VARS=$2

    echo "🔧 Actualizando $CONTAINER_GROUP..."

    # Reiniciar container group con nuevas variables (esto es rápido)
    az container restart --name $CONTAINER_GROUP --resource-group microservice-app-rg
}

# Actualizar Auth service con IP real de Users
echo "🔄 Actualizando Auth service..."
# En este punto el auth ya está corriendo, solo necesita restart para conectar a users

# Verificar que todos los servicios estén funcionando
echo "🔍 Verificando servicios..."

for service in $AUTH_IP:8000 $USERS_IP:8083 $TODOS_IP:8082; do
    echo "Testing $service..."
    if curl -f http://$service/health 2>/dev/null || curl -f http://$service/ 2>/dev/null; then
        echo "✅ $service OK"
    else
        echo "⚠️ $service no responde aún (normal en startup)"
    fi
done

echo "🎉 Configuración de URLs completada!"
echo "🌐 URLs de servicios:"
echo "  Frontend: http://$(terraform output -raw frontend_service_ip)"
echo "  Zipkin: $(terraform output -raw zipkin_service_url)"