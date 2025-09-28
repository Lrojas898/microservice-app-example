#!/bin/bash

# Deploy conservador paso a paso
# Para debugging y casos donde el deploy rápido falla

set -e

echo "🐌 Deploy conservador - paso a paso con validación..."

# Función para esperar y validar cada paso
wait_and_validate() {
    local resource_name=$1
    local check_command=$2

    echo "⏳ Esperando que $resource_name esté listo..."

    for i in {1..30}; do
        if eval $check_command &>/dev/null; then
            echo "✅ $resource_name está listo"
            return 0
        fi
        echo "   Intento $i/30..."
        sleep 10
    done

    echo "❌ $resource_name no está listo después de 5 minutos"
    return 1
}

# PASO 1: Resource Group
echo "📦 [1/10] Creando Resource Group..."
terraform apply -target=azurerm_resource_group.main -auto-approve -var-file="terraform.tfvars"
wait_and_validate "Resource Group" "az group show --name microservice-app-rg"

# PASO 2: Network
echo "🌐 [2/10] Creando red virtual..."
terraform apply -target=module.network -auto-approve -var-file="terraform.tfvars"
wait_and_validate "VNet" "az network vnet show --name microservice-vnet --resource-group microservice-app-rg"

# PASO 3: Random string (para nombres únicos)
echo "🎲 [3/10] Generando strings únicos..."
terraform apply -target=random_string.unique -auto-approve -var-file="terraform.tfvars"

# PASO 4: Redis Cache
echo "🗄️ [4/10] Creando Redis Cache..."
terraform apply -target=module.security -auto-approve -var-file="terraform.tfvars"
wait_and_validate "Redis" "az redis show --name microservice-redis-optimized-* --resource-group microservice-app-rg"

# PASO 5: PostgreSQL
echo "🐘 [5/10] Creando PostgreSQL..."
terraform apply -target=azurerm_postgresql_flexible_server.consolidated -auto-approve -var-file="terraform.tfvars"
wait_and_validate "PostgreSQL" "az postgres flexible-server show --name postgres-consolidated-* --resource-group microservice-app-rg"

# PASO 6: Zipkin VM
echo "🖥️ [6/10] Creando Zipkin VM..."
terraform apply -target=azurerm_public_ip.zipkin \
                -target=azurerm_network_security_group.zipkin \
                -target=azurerm_network_interface.zipkin \
                -target=azurerm_linux_virtual_machine.zipkin \
                -auto-approve -var-file="terraform.tfvars"
wait_and_validate "Zipkin VM" "az vm show --name zipkin-vm --resource-group microservice-app-rg"

# PASO 7: Users Service (sin dependencias complejas)
echo "👥 [7/10] Creando Users Service..."
terraform apply -target=azurerm_container_group.users -auto-approve -var-file="terraform.tfvars"
wait_and_validate "Users Service" "az container show --name users-service --resource-group microservice-app-rg"

# PASO 8: Auth Service
echo "🔐 [8/10] Creando Auth Service..."
terraform apply -target=azurerm_container_group.auth -auto-approve -var-file="terraform.tfvars"
wait_and_validate "Auth Service" "az container show --name auth-service --resource-group microservice-app-rg"

# PASO 9: Todos Service
echo "📝 [9/10] Creando Todos Service..."
terraform apply -target=azurerm_container_group.todos -auto-approve -var-file="terraform.tfvars"
wait_and_validate "Todos Service" "az container show --name todos-service --resource-group microservice-app-rg"

# PASO 10: Frontend y Log Processor
echo "🌐 [10/10] Creando Frontend y Log Processor..."
terraform apply -target=azurerm_container_group.frontend \
                -target=azurerm_container_group.log_processor \
                -auto-approve -var-file="terraform.tfvars"

# Final apply
echo "🔧 Aplicando configuración final..."
terraform apply -auto-approve -var-file="terraform.tfvars"

echo ""
echo "✅ Deploy conservador completado!"
echo "⏱️ Este método es más lento pero más confiable para debugging"
echo ""
echo "🌐 URLs finales:"
terraform output zipkin_service_url
terraform output frontend_url