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

output "gateway_subnet_id" {
  value = azurerm_subnet.gateway.id
}

output "cache_subnet_id" {
  value = azurerm_subnet.cache.id
}