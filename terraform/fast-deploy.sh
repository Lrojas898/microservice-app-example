#!/bin/bash

# Script de deploy ultra-rápido con orden óptimo
# Respeta dependencias críticas y maximiza paralelización

set -e

echo "🚀 Iniciando deploy ultra-rápido con orden optimizado (sin Zipkin)..."

# Configurar Terraform para máxima paralelización
export TF_CLI_ARGS="-parallelism=20"

# NIVEL 0: Infraestructura base (2-3 minutos)
echo "🏗️ [Nivel 0] Desplegando infraestructura base..."
terraform apply -target=azurerm_resource_group.main \
                -target=random_string.unique \
                -target=module.network \
                -auto-approve -var-file="terraform.tfvars"

# NIVEL 1: Servicios de infraestructura en paralelo (3-4 minutos)
echo "🗄️ [Nivel 1] Desplegando servicios de infraestructura..."
terraform apply -target=module.security \
                -target=azurerm_postgresql_flexible_server.consolidated \
                -auto-approve -var-file="terraform.tfvars"

# NIVEL 2: Servicios simples sin dependencias críticas (2-3 minutos)
echo "🔧 [Nivel 2] Desplegando servicios independientes..."
terraform apply -target=azurerm_container_group.users \
                -target=azurerm_container_group.log_processor \
                -auto-approve -var-file="terraform.tfvars"

# NIVEL 3: Servicios con dependencias de DB (2-3 minutos)
echo "📊 [Nivel 3] Desplegando servicios con base de datos..."
terraform apply -target=azurerm_container_group.auth \
                -target=azurerm_container_group.todos \
                -auto-approve -var-file="terraform.tfvars"

# NIVEL 4: Frontend (necesita IPs de servicios) (1-2 minutos)
echo "🌐 [Nivel 4] Desplegando frontend..."
terraform apply -target=azurerm_container_group.frontend \
                -auto-approve -var-file="terraform.tfvars"

# NIVEL 5: Finalización y outputs
echo "🔧 [Nivel 5] Finalizando configuración..."
terraform apply -auto-approve -var-file="terraform.tfvars"

# Post-deploy: Actualizar URLs entre servicios
echo "🔄 Actualizando URLs de servicios..."
chmod +x update-service-urls.sh
./update-service-urls.sh

echo "✅ Deploy completado!"
echo "⏱️ Tiempo total estimado: 10-15 minutos"
echo ""
echo "🌐 URLs finales:"
terraform output frontend_url

echo ""
echo "📊 Resumen del deploy por niveles:"
echo "  Nivel 0: Infraestructura base → 2-3 min"
echo "  Nivel 1: Servicios core → 3-4 min"
echo "  Nivel 2: Servicios simples → 2-3 min"
echo "  Nivel 3: Servicios con DB → 2-3 min"
echo "  Nivel 4: Frontend → 1-2 min"
echo "  Nivel 5: Finalización → 1 min"