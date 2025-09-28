#!/bin/bash

# Script para actualizar URLs de servicios post-deploy
# Soluciona las dependencias circulares entre servicios

set -e

echo "🔗 Actualizando URLs de servicios post-deploy..."

# Obtener IPs de los servicios
echo "📍 Obteniendo IPs de servicios..."

AUTH_IP=$(az container show --name auth-service --resource-group microservice-app-rg --query "ipAddress.ip" -o tsv 2>/dev/null || echo "")
USERS_IP=$(az container show --name users-service --resource-group microservice-app-rg --query "ipAddress.ip" -o tsv 2>/dev/null || echo "")
TODOS_IP=$(az container show --name todos-service --resource-group microservice-app-rg --query "ipAddress.ip" -o tsv 2>/dev/null || echo "")
FRONTEND_IP=$(az container show --name frontend-service --resource-group microservice-app-rg --query "ipAddress.ip" -o tsv 2>/dev/null || echo "")

echo "Auth Service IP: $AUTH_IP"
echo "Users Service IP: $USERS_IP"
echo "Todos Service IP: $TODOS_IP"
echo "Frontend Service IP: $FRONTEND_IP"

# Verificar que todos los servicios estén corriendo
if [ -z "$AUTH_IP" ] || [ -z "$USERS_IP" ] || [ -z "$TODOS_IP" ]; then
    echo "❌ No se pudieron obtener todas las IPs de servicios"
    echo "Verificar que todos los containers estén corriendo:"
    echo "az container list --resource-group microservice-app-rg --output table"
    exit 1
fi

echo ""
echo "✅ Todas las IPs obtenidas correctamente!"
echo ""
echo "🔧 Para aplicar las URLs automáticamente:"
echo "========================================="

# Función de auto-actualización
if [ "$1" = "--auto-update" ]; then
    echo ""
    echo "🚀 Aplicando auto-actualización..."

    # Backup del archivo original
    cp aci.tf aci.tf.backup.$(date +%Y%m%d_%H%M%S)

    # Actualizar placeholder con IP real
    sed -i "s|http://placeholder-users:8083|http://$USERS_IP:8083|g" aci.tf

    echo "✅ aci.tf actualizado con IP real: $USERS_IP"
    echo "💡 Ejecutar: terraform apply -target=azurerm_container_group.auth -auto-approve -var-file=\"terraform.tfvars\""

    # Aplicar el cambio automáticamente
    echo "🚀 Aplicando cambios..."
    terraform apply -target=azurerm_container_group.auth -auto-approve -var-file="terraform.tfvars"

    echo "✅ Auth service actualizado con URL real de Users service"
else
    echo "1. Actualizar aci.tf con las IPs reales:"
    echo "   sed -i 's|http://placeholder-users:8083|http://$USERS_IP:8083|g' aci.tf"
    echo ""
    echo "2. Aplicar los cambios:"
    echo "   terraform apply -target=azurerm_container_group.auth -auto-approve -var-file=\"terraform.tfvars\""
    echo ""
    echo "3. O ejecutar con auto-actualización:"
    echo "   ./update-service-urls.sh --auto-update"
fi

echo ""
echo "🔍 Verificando servicios..."

for service in "$AUTH_IP:8000" "$USERS_IP:8083" "$TODOS_IP:8082"; do
    echo "Testing $service..."
    if curl -f "http://$service/actuator/health" 2>/dev/null || curl -f "http://$service/" 2>/dev/null; then
        echo "✅ $service OK"
    else
        echo "⚠️ $service no responde aún (normal en startup)"
    fi
done

echo ""
echo "🎯 URLs finales:"
echo "=================="
echo "Frontend: http://$FRONTEND_IP"
echo "Auth Health: http://$AUTH_IP:8000/actuator/health"
echo "Users Health: http://$USERS_IP:8083/actuator/health"
echo "Todos Health: http://$TODOS_IP:8082/actuator/health"