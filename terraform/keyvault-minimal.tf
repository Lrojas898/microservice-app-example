# Configuración temporal SIN Key Vault para evitar errores de permisos
# Esta es una configuración mínima que permite desplegar la infraestructura optimizada

# Data source para obtener información del cliente actual (comentado)
# data "azurerm_client_config" "current" {}

# TEMPORALMENTE DESHABILITADO - Key Vault que causa problemas de permisos
# Descomentar cuando se resuelvan los permisos

# resource "azurerm_key_vault" "main" {
#   name                = var.key_vault_name
#   location            = azurerm_resource_group.main.location
#   resource_group_name = azurerm_resource_group.main.name
#   tenant_id           = data.azurerm_client_config.current.tenant_id
#   sku_name            = "standard"

#   enabled_for_disk_encryption     = true
#   enabled_for_deployment          = true
#   enabled_for_template_deployment = true
#   purge_protection_enabled        = false

#   depends_on = [azurerm_resource_group.main]
# }

# resource "azurerm_key_vault_access_policy" "current" {
#   key_vault_id = azurerm_key_vault.main.id
#   tenant_id    = data.azurerm_client_config.current.tenant_id
#   object_id    = data.azurerm_client_config.current.object_id

#   secret_permissions = [
#     "Get", "List", "Set", "Delete", "Backup", "Restore", "Recover", "Purge"
#   ]

#   key_permissions = [
#     "Get", "List", "Create", "Delete", "Update", "Import", "Backup", "Restore", "Recover"
#   ]

#   certificate_permissions = [
#     "Get", "List", "Create", "Delete", "Update", "Import", "Backup", "Restore", "Recover"
#   ]
# }

# NOTA: La infraestructura funcionará sin Key Vault
# Las contraseñas estarán disponibles en los outputs de Terraform
