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

  # Política de acceso para el usuario actual
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "Get", "List", "Create", "Delete", "Update", "Import", "Backup", "Restore", "Recover"
    ]

    secret_permissions = [
      "Get", "List", "Set", "Delete", "Backup", "Restore", "Recover"
    ]

    certificate_permissions = [
      "Get", "List", "Create", "Delete", "Update", "Import", "Backup", "Restore", "Recover"
    ]
  }

  # Política de acceso para el service principal de Terraform (oid: ed9eb106-e194-4ce0-9814-f9d70de65329)
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = "ed9eb106-e194-4ce0-9814-f9d70de65329"

    secret_permissions = [
      "Get", "List", "Purge"
    ]
  }
  # Garantizar que el grupo de recursos exista antes de crear el Key Vault
  depends_on = [azurerm_resource_group.main]
}

# Data source para obtener información del cliente actual
data "azurerm_client_config" "current" {}

# Las contraseñas aleatorias se generan en databases.tf

# Almacenar contraseñas en Key Vault
resource "azurerm_key_vault_secret" "postgres_auth_password" {
  name         = "postgres-auth-password"
  value        = var.postgres_auth_password != null ? var.postgres_auth_password : random_password.postgres_auth_password[0].result
  key_vault_id = azurerm_key_vault.main.id
}

resource "azurerm_key_vault_secret" "postgres_users_password" {
  name         = "postgres-users-password"
  value        = var.postgres_users_password != null ? var.postgres_users_password : random_password.postgres_users_password[0].result
  key_vault_id = azurerm_key_vault.main.id
}

resource "azurerm_key_vault_secret" "postgres_todos_password" {
  name         = "postgres-todos-password"
  value        = var.postgres_todos_password != null ? var.postgres_todos_password : random_password.postgres_todos_password[0].result
  key_vault_id = azurerm_key_vault.main.id
}
