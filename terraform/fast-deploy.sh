#!/bin/bash

# Script de deploy ultra-rápido
# Utiliza paralelización y optimizaciones para acelerar ACI

set -e

echo "🚀 Iniciando deploy ultra-rápido..."

# Configurar Terraform para máxima paralelización
export TF_CLI_ARGS="-parallelism=20"

# Step 1: Deploy infraestructura base en paralelo
echo "📦 Desplegando infraestructura base..."
terraform apply -target=azurerm_resource_group.main \
                -target=module.network \
                -target=module.security \
                -auto-approve -var-file="terraform.tfvars"

# Step 2: Deploy Zipkin VM (independiente, más rápido que containers)
echo "🖥️ Desplegando Zipkin VM..."
terraform apply -target=azurerm_public_ip.zipkin \
                -target=azurerm_network_security_group.zipkin \
                -target=azurerm_network_interface.zipkin \
                -target=azurerm_linux_virtual_machine.zipkin \
                -auto-approve -var-file="terraform.tfvars"

# Step 3: Deploy base de datos
echo "🗄️ Desplegando PostgreSQL..."
terraform apply -target=azurerm_postgresql_flexible_server.consolidated \
                -auto-approve -var-file="terraform.tfvars"

# Step 4: Deploy todos los containers en paralelo (sin dependencias cruzadas)
echo "📦 Desplegando containers en paralelo..."
terraform apply -target=azurerm_container_group.auth \
                -target=azurerm_container_group.users \
                -target=azurerm_container_group.todos \
                -target=azurerm_container_group.log_processor \
                -target=azurerm_container_group.frontend \
                -auto-approve -var-file="terraform.tfvars"

# Step 5: Apply final para outputs y dependencias
echo "🔧 Finalizando configuración..."
terraform apply -auto-approve -var-file="terraform.tfvars"

# Step 6: Actualizar URLs entre servicios
echo "🔄 Actualizando URLs de servicios..."
chmod +x update-service-urls.sh
./update-service-urls.sh

echo "✅ Deploy completado!"
echo "🌐 URLs finales:"
terraform output zipkin_service_url
terraform output frontend_url