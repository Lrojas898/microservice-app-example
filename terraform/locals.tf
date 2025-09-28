# IP addresses que se actualizarán después del despliegue inicial
locals {
  # IPs públicas que se obtendrán después del primer despliegue
  auth_service_ip    = try(azurerm_container_group.auth.ip_address, "127.0.0.1")
  users_service_ip   = try(azurerm_container_group.users.ip_address, "127.0.0.1")
  todos_service_ip   = try(azurerm_container_group.todos.ip_address, "127.0.0.1")
  frontend_service_ip = try(azurerm_container_group.frontend.ip_address, "127.0.0.1")
  zipkin_service_ip  = try(azurerm_container_group.zipkin.ip_address, "127.0.0.1")
}