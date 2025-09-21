variable "resource_group_name" {
  description = "Nombre del grupo de recursos"
  type        = string
}

variable "location" {
  description = "Región de Azure"
  type        = string
}

variable "cache_subnet_id" {
  description = "ID de la subnet para Azure Cache for Redis"
  type        = string
}

variable "gateway_subnet_id" {
  description = "ID de la subnet para Application Gateway"
  type        = string
}

variable "vnet_id" {
  description = "ID de la red virtual principal para DNS link"
  type        = string
}

variable "frontend_container_ip" {
  description = "IP privada del contenedor frontend para Application Gateway"
  type        = string
}

variable "users_container_ip" {
  description = "IP privada del contenedor users para Application Gateway"
  type        = string
}
