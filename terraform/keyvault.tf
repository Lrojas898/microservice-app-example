# Data source para obtener información del cliente actual
data "azurerm_client_config" "current" {}

# Azure Key Vault para almacenar secretos
resource "azurerm_key_vault" "main" {
  name                = var.key_vault_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  # Habilitar acceso desde Azure AD
  enabled_for_disk_encryption     = true
  enabled_for_deployment          = true
  enabled_for_template_deployment = true
  purge_protection_enabled        = false

  # Garantizar que el grupo de recursos exista antes de crear el Key Vault
  depends_on = [azurerm_resource_group.main]
}

# Política de acceso para el service principal actual (GitHub Actions)
resource "azurerm_key_vault_access_policy" "current" {
  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  secret_permissions = [
    "Get",
    "List",
    "Set",
    "Delete",
    "Backup",
    "Restore",
    "Recover",
    "Purge"
  ]

  key_permissions = [
    "Get",
    "List",
    "Create",
    "Delete",
    "Update",
    "Import",
    "Backup",
    "Restore",
    "Recover"
  ]

  certificate_permissions = [
    "Get",
    "List",
    "Create",
    "Delete",
    "Update",
    "Import",
    "Backup",
    "Restore",
    "Recover"
  ]
}

# Las contraseñas aleatorias se generan en databases.tf
# Almacenar contraseñas en Key Vault
resource "azurerm_key_vault_secret" "postgres_auth_password" {
  name         = "postgres-auth-password"
  value        = var.postgres_auth_password != null ? var.postgres_auth_password : random_password.postgres_auth_password[0].result
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [azurerm_key_vault_access_policy.current]
}

resource "azurerm_key_vault_secret" "postgres_users_password" {
  name         = "postgres-users-password"
  value        = var.postgres_users_password != null ? var.postgres_users_password : random_password.postgres_users_password[0].result
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [azurerm_key_vault_access_policy.current]
}

resource "azurerm_key_vault_secret" "postgres_todos_password" {
  name         = "postgres-todos-password"
  value        = var.postgres_todos_password != null ? var.postgres_todos_password : random_password.postgres_todos_password[0].result
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [azurerm_key_vault_access_policy.current]
}
