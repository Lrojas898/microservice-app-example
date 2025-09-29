# Application Gateway outputs removed - using direct service access

output "redis_cache_hostname" {
  value = azurerm_redis_cache.main.hostname
}

output "redis_cache_primary_key" {
  value     = azurerm_redis_cache.main.primary_access_key
  sensitive = true
}
