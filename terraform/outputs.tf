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

output "gateway_subnet_id" {
  value = module.network.gateway_subnet_id
}

output "cache_subnet_id" {
  value = module.network.cache_subnet_id
}

output "application_gateway_name" {
  value = module.security.application_gateway_name
}

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

# Application Gateway Public Access
output "application_gateway_public_ip" {
  value = module.security.application_gateway_public_ip
}

output "frontend_url" {
  value = "http://${module.security.application_gateway_public_ip}"
}

output "frontend_private_ip" {
  value = azurerm_container_group.frontend.ip_address
}
