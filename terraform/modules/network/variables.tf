variable "resource_group_name" {
  description = "Nombre del grupo de recursos"
  type        = string
}

variable "location" {
  description = "Región de Azure"
  type        = string
}

variable "vnet_address_space" {
  description = "Espacio de direcciones para la red virtual"
  type        = list(string)
}

variable "auth_subnet_prefix" {
  description = "Prefijo de dirección para la subnet de Auth"
  type        = string
}

variable "users_subnet_prefix" {
  description = "Prefijo de dirección para la subnet de Users"
  type        = string
}

variable "todos_subnet_prefix" {
  description = "Prefijo de dirección para la subnet de Todos"
  type        = string
}

# Gateway subnet prefix removed - Application Gateway eliminated

variable "cache_subnet_prefix" {
  description = "Prefijo de dirección para la subnet de Cache"
  type        = string
}

# Container subnet prefixes removed - using public IPs for direct access
