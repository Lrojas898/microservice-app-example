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

variable "vnet_id" {
  description = "ID de la red virtual principal para DNS link"
  type        = string
}

# Application Gateway variables removed - no longer needed

variable "unique_suffix" {
  description = "Sufijo único para nombres de recursos"
  type        = string
}
