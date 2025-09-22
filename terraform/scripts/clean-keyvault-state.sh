#!/bin/bash

# Script para limpiar el estado de Terraform de recursos problemáticos del Key Vault
# Esto removerá las referencias a los secretos que causan errores 403

set -e

echo "🧹 Limpiando estado de Terraform..."

# Lista de recursos a remover del estado
resources_to_remove=(
    "azurerm_key_vault_secret.postgres_auth_password"
    "azurerm_key_vault_secret.postgres_users_password" 
    "azurerm_key_vault_secret.postgres_todos_password"
    "azurerm_key_vault_secret.postgres_consolidated_password"
)

echo "🔍 Verificando qué recursos existen en el estado..."

for resource in "${resources_to_remove[@]}"; do
    if terraform state list | grep -q "^${resource}$"; then
        echo "❌ Removiendo del estado: $resource"
        terraform state rm "$resource" || echo "⚠️  No se pudo remover $resource (puede que no exista)"
    else
        echo "✅ No encontrado en el estado: $resource"
    fi
done

echo ""
echo "🔍 Verificando otras posibles referencias problemáticas..."

# Verificar otros recursos del Key Vault que puedan causar problemas
if terraform state list | grep -q "azurerm_key_vault.main"; then
    echo "ℹ️  Key Vault principal encontrado en el estado (esto está bien)"
else
    echo "⚠️  Key Vault principal no encontrado en el estado"
fi

if terraform state list | grep -q "azurerm_key_vault_access_policy.current"; then
    echo "ℹ️  Política de acceso encontrada en el estado (esto está bien)"
else
    echo "⚠️  Política de acceso no encontrada en el estado"
fi

echo ""
echo "✅ Limpieza del estado completada!"
echo ""
echo "🔄 Próximos pasos:"
echo "1. Ejecutar: terraform plan"
echo "2. Si no hay errores: terraform apply"
echo "3. Los secretos se pueden agregar manualmente después en Azure Portal"

echo ""
echo "💡 Nota: Esto no elimina los recursos de Azure, solo los remueve del estado de Terraform"
echo "   Los secretos seguirán existiendo en Azure si ya estaban creados"