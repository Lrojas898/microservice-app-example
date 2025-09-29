#!/bin/bash

# Solución rápida: Deshabilitar temporalmente el Key Vault

set -e

echo "🚫 Deshabilitando temporalmente Key Vault..."

# Renombrar keyvault.tf para que Terraform no lo procese
if [ -f "keyvault.tf" ]; then
    mv keyvault.tf keyvault.tf.disabled
    echo "✅ keyvault.tf renombrado a keyvault.tf.disabled"
else
    echo "ℹ️  keyvault.tf no encontrado"
fi

# Limpiar estado de Key Vault si existe
echo "🧹 Limpiando estado de Key Vault..."

resources_to_remove=(
    "azurerm_key_vault_secret.postgres_auth_password"
    "azurerm_key_vault_secret.postgres_users_password" 
    "azurerm_key_vault_secret.postgres_todos_password"
    "azurerm_key_vault_secret.postgres_consolidated_password"
    "azurerm_key_vault_access_policy.current"
    "azurerm_key_vault.main"
    "data.azurerm_client_config.current"
)

for resource in "${resources_to_remove[@]}"; do
    if terraform state list 2>/dev/null | grep -q "^${resource}$"; then
        echo "❌ Removiendo del estado: $resource"
        terraform state rm "$resource" 2>/dev/null || echo "⚠️  No se pudo remover $resource"
    fi
done

echo ""
echo "✅ Key Vault deshabilitado temporalmente!"
echo ""
echo "🔄 Ahora puedes ejecutar:"
echo "   terraform plan"
echo "   terraform apply"
echo ""
echo "🔄 Para rehabilitar Key Vault después:"
echo "   mv keyvault.tf.disabled keyvault.tf"
echo "   # Resolver permisos en Azure Portal"
echo "   terraform plan"
echo "   terraform apply"