output "application_gateway_name" {
  value = azurerm_application_gateway.main.name
}

output "application_gateway_public_ip" {
  value = azurerm_public_ip.appgw.ip_address
}

output "redis_cache_hostname" {
  value = azurerm_redis_cache.main.hostname
}

output "redis_cache_primary_key" {
  value     = azurerm_redis_cache.main.primary_access_key
  sensitive = true
}
