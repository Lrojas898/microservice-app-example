# Variables globales
variable "resource_group_name" {
  description = "Nombre del grupo de recursos en Azure"
  type        = string
  default     = "microservice-app-rg"
}

variable "location" {
  description = "Región de Azure"
  type        = string
  default     = "westus2"
}

variable "resource_group_location" {
  description = "Región del Resource Group (no mover si ya existe)"
  type        = string
  default     = "westus2"
}

variable "db_location" {
  description = "Región para PostgreSQL Flexible Servers"
  type        = string
  default     = "westus2"
}

# Variables para la red virtual
variable "vnet_address_space" {
  description = "Espacio de direcciones para la red virtual"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

# Subnets
variable "auth_subnet_prefix" {
  description = "Prefijo de dirección para la subnet de Auth"
  type        = string
  default     = "10.0.1.0/24"
}

variable "users_subnet_prefix" {
  description = "Prefijo de dirección para la subnet de Users"
  type        = string
  default     = "10.0.2.0/24"
}

variable "todos_subnet_prefix" {
  description = "Prefijo de dirección para la subnet de Todos"
  type        = string
  default     = "10.0.3.0/24"
}

variable "gateway_subnet_prefix" {
  description = "Prefijo de dirección para la subnet del Gateway"
  type        = string
  default     = "10.0.4.0/24"
}

variable "cache_subnet_prefix" {
  description = "Prefijo de dirección para la subnet de Cache"
  type        = string
  default     = "10.0.5.0/24"
}

# Variables para contraseñas de bases de datos
variable "postgres_auth_password" {
  description = "Contraseña para el servidor PostgreSQL de Auth"
  type        = string
  sensitive   = true
  default     = null
}

variable "postgres_users_password" {
  description = "Contraseña para el servidor PostgreSQL de Users"
  type        = string
  sensitive   = true
  default     = null
}

variable "postgres_todos_password" {
  description = "Contraseña para el servidor PostgreSQL de Todos"
  type        = string
  sensitive   = true
  default     = null
}

# Variable para Key Vault
variable "key_vault_name" {
  description = "Nombre del Key Vault para almacenar secretos"
  type        = string
  default     = "microservice-kv"
}