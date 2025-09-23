output "vnet_id" {
  value = azurerm_virtual_network.main.id
}

output "auth_subnet_id" {
  value = azurerm_subnet.auth.id
}

output "users_subnet_id" {
  value = azurerm_subnet.users.id
}

output "todos_subnet_id" {
  value = azurerm_subnet.todos.id
}

# Gateway subnet output removed - Application Gateway eliminated

output "cache_subnet_id" {
  value = azurerm_subnet.cache.id
}

# Container subnet outputs removed - using public IPs for direct access
