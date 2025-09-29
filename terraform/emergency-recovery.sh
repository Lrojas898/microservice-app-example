#!/bin/bash

# Script de recuperación de emergencia para deploy bloqueado

set -e

echo "🚨 RECUPERACIÓN DE EMERGENCIA - Auth Container Bloqueado"
echo "=================================================="

# Función para esperar confirmación del usuario
confirm() {
    read -p "$1 [y/N]: " response
    case "$response" in
        [yY][eE][sS]|[yY])
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# 1. Diagnóstico inicial
echo "🔍 DIAGNÓSTICO INICIAL"
echo "====================="

echo "Estado de Terraform:"
pgrep -f "terraform apply" && echo "✅ Terraform está corriendo" || echo "❌ Terraform no está corriendo"

echo ""
echo "Estado del Auth Container:"
az container show --name auth-service --resource-group microservice-app-rg --query "containers[0].instanceView.currentState" 2>/dev/null && echo "✅ Auth container existe" || echo "❌ Auth container no existe"

echo ""
echo "Últimos logs del Auth:"
az container logs --name auth-service --resource-group microservice-app-rg --tail 10 2>/dev/null || echo "❌ No hay logs"

# 2. Opciones de recuperación
echo ""
echo "🔧 OPCIONES DE RECUPERACIÓN"
echo "========================="

if confirm "1. ¿Cancelar proceso de Terraform actual?"; then
    echo "⏹️ Cancelando Terraform..."
    pkill -f "terraform apply" || true
    sleep 2
fi

if confirm "2. ¿Destruir auth container problemático?"; then
    echo "💥 Destruyendo auth container..."
    terraform destroy -target=azurerm_container_group.auth -auto-approve -var-file="terraform.tfvars" || true
fi

if confirm "3. ¿Hacer deploy conservador paso a paso?"; then
    echo "🐌 Iniciando deploy conservador..."
    chmod +x conservative-deploy.sh
    ./conservative-deploy.sh
    exit 0
fi

if confirm "4. ¿Intentar deploy rápido con fix aplicado?"; then
    echo "⚡ Intentando deploy rápido con fix..."

    # Aplicar fix de URL
    echo "🔧 Aplicando fix de USERS_API_ADDRESS..."

    # Deploy solo del auth con configuración corregida
    terraform apply -target=azurerm_container_group.auth -auto-approve -var-file="terraform.tfvars"

    if [ $? -eq 0 ]; then
        echo "✅ Auth container desplegado correctamente!"
        echo "🔄 Continuando con el resto del deploy..."
        ./fast-deploy.sh
    else
        echo "❌ Auth container sigue fallando"
        echo "💡 Recomendación: Usar deploy conservador"
    fi
fi

if confirm "5. ¿Restart completo de la infraestructura?"; then
    echo "🔄 RESTART COMPLETO - Esto destruirá todo y empezará desde cero"
    if confirm "   ¿Estás SEGURO? Esto borrará toda la infraestructura"; then
        echo "💥 Destruyendo toda la infraestructura..."
        terraform destroy -auto-approve -var-file="terraform.tfvars"
        echo "🚀 Desplegando desde cero..."
        ./fast-deploy.sh
    fi
fi

echo ""
echo "🔍 COMANDOS ÚTILES PARA DEBUGGING:"
echo "================================="
echo "Ver logs auth:     az container logs --name auth-service --resource-group microservice-app-rg --follow"
echo "Estado auth:       az container show --name auth-service --resource-group microservice-app-rg"
echo "Listar containers: az container list --resource-group microservice-app-rg --output table"
echo "Terraform state:   terraform state list"
echo ""
echo "🆘 Si nada funciona, contacta con soporte técnico con los logs anteriores."