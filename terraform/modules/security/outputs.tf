output "redis_cache_id" {
  value = azurerm_redis_cache.main.id
}

output "application_gateway_id" {
  value = azurerm_application_gateway.main.id
}