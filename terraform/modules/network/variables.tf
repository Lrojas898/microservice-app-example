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

variable "gateway_subnet_prefix" {
  description = "Prefijo de dirección para la subnet del Gateway"
  type        = string
}

variable "cache_subnet_prefix" {
  description = "Prefijo de dirección para la subnet de Cache"
  type        = string
}

variable "auth_container_subnet_prefix" {
  description = "Prefijo de dirección para la subnet de Auth Container"
  type        = string
}

variable "users_container_subnet_prefix" {
  description = "Prefijo de dirección para la subnet de Users Container"
  type        = string
}

variable "todos_container_subnet_prefix" {
  description = "Prefijo de dirección para la subnet de Todos Container"
  type        = string
}

variable "frontend_container_subnet_prefix" {
  description = "Prefijo de dirección para la subnet de Frontend Container"
  type        = string
}
