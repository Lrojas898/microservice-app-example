# Key Vault temporalmente deshabilitado debido a problemas de permisos
# Descomenta este archivo y renómbralo a keyvault.tf cuando tengas permisos resueltos

# # Data source para obtener información del cliente actual
# data "azurerm_client_config" "current" {}

# # Azure Key Vault para almacenar secretos
# resource "azurerm_key_vault" "main" {
#   name                = var.key_vault_name
#   location            = azurerm_resource_group.main.location
#   resource_group_name = azurerm_resource_group.main.name
#   tenant_id           = data.azurerm_client_config.current.tenant_id
#   sku_name            = "standard"

#   # Habilitar acceso desde Azure AD
#   enabled_for_disk_encryption     = true
#   enabled_for_deployment          = true
#   enabled_for_template_deployment = true
#   purge_protection_enabled        = false

#   # Garantizar que el grupo de recursos exista antes de crear el Key Vault
#   depends_on = [azurerm_resource_group.main]
# }

# # Política de acceso para el service principal actual (GitHub Actions)
# resource "azurerm_key_vault_access_policy" "current" {
#   key_vault_id = azurerm_key_vault.main.id
#   tenant_id    = data.azurerm_client_config.current.tenant_id
#   object_id    = data.azurerm_client_config.current.object_id

#   secret_permissions = [
#     "Get",
#     "List",
#     "Set",
#     "Delete",
#     "Backup",
#     "Restore",
#     "Recover",
#     "Purge"
#   ]

#   key_permissions = [
#     "Get",
#     "List",
#     "Create",
#     "Delete",
#     "Update",
#     "Import",
#     "Backup",
#     "Restore",
#     "Recover"
#   ]

#   certificate_permissions = [
#     "Get",
#     "List",
#     "Create",
#     "Delete",
#     "Update",
#     "Import",
#     "Backup",
#     "Restore",
#     "Recover"
#   ]
# }
