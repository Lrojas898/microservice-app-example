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
  value = azurerm_application_gateway.main.name
}

output "redis_cache_hostname" {
  value = azurerm_redis_cache.main.hostname
}