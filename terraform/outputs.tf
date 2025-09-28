output "resource_group_name" {
  value = azurerm_resource_group.main.name
}

output "vnet_id" {
  value = module.network.vnet_id
}

output "auth_subnet_id" {
  value = module.network.auth_subnet_id
}

output "users_subnet_id" {
  value = module.network.users_subnet_id
}

output "todos_subnet_id" {
  value = module.network.todos_subnet_id
}

# Gateway subnet output removed - Application Gateway eliminated

output "cache_subnet_id" {
  value = module.network.cache_subnet_id
}

# Application Gateway outputs removed

output "redis_cache_hostname" {
  value = module.security.redis_cache_hostname
}

output "redis_cache_primary_key" {
  value     = module.security.redis_cache_primary_key
  sensitive = true
}

# Outputs para Key Vault - TEMPORALMENTE COMENTADOS debido a problemas de permisos
# output "key_vault_name" {
#   value = azurerm_key_vault.main.name
# }

# output "key_vault_uri" {
#   value = azurerm_key_vault.main.vault_uri
# }

# Outputs para contraseñas consolidadas
output "postgres_consolidated_password" {
  value     = random_password.postgres_consolidated_password.result
  sensitive = true
}

output "postgres_auth_password" {
  value     = var.postgres_auth_password != null ? var.postgres_auth_password : random_password.postgres_consolidated_password.result
  sensitive = true
}

output "postgres_users_password" {
  value     = var.postgres_users_password != null ? var.postgres_users_password : random_password.postgres_consolidated_password.result
  sensitive = true
}

output "postgres_todos_password" {
  value     = var.postgres_todos_password != null ? var.postgres_todos_password : random_password.postgres_consolidated_password.result
  sensitive = true
}

# Service Public URLs for direct access
output "zipkin_service_url" {
  value       = "https://${azurerm_container_app.zipkin.latest_revision_fqdn}"
  description = "Zipkin Container App URL (Brazil South)"
}

output "zipkin_service_fqdn" {
  value       = azurerm_container_app.zipkin.latest_revision_fqdn
  description = "Zipkin Container App FQDN (Brazil South)"
}

output "auth_service_ip" {
  value = azurerm_container_group.auth.ip_address
}

output "users_service_ip" {
  value = azurerm_container_group.users.ip_address
}

output "todos_service_ip" {
  value = azurerm_container_group.todos.ip_address
}

output "frontend_service_ip" {
  value = azurerm_container_group.frontend.ip_address
}

output "frontend_url" {
  value = "http://${azurerm_container_group.frontend.ip_address}"
}

# Unique suffix for resource naming
output "unique_suffix" {
  value = random_string.unique.result
}
