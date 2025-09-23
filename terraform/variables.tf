# Variables globales
variable "resource_group_name" {
  description = "Nombre del grupo de recursos en Azure"
  type        = string
  default     = "microservice-app-rg"
}

variable "location" {
  description = "Región de Azure"
  type        = string
  default     = "chilecentral"
}

variable "resource_group_location" {
  description = "Región del Resource Group (no mover si ya existe)"
  type        = string
  default     = "chilecentral"
}

variable "db_location" {
  description = "Región para PostgreSQL Flexible Servers"
  type        = string
  default     = "chilecentral"
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

# Gateway subnet prefix removed - Application Gateway eliminated
# variable "gateway_subnet_prefix" {
#   description = "Prefijo de dirección para la subnet del Gateway"
#   type        = string
#   default     = "10.0.4.0/24"
# }

variable "cache_subnet_prefix" {
  description = "Prefijo de dirección para la subnet de Cache"
  type        = string
  default     = "10.0.5.0/24"
}

# Container subnet prefixes removed - using public IPs for direct access
# variable "auth_container_subnet_prefix" {
#   description = "Prefijo de dirección para la subnet de Auth Container"
#   type        = string
#   default     = "10.0.6.0/24"
# }

# variable "users_container_subnet_prefix" {
#   description = "Prefijo de dirección para la subnet de Users Container"
#   type        = string
#   default     = "10.0.7.0/24"
# }

# variable "todos_container_subnet_prefix" {
#   description = "Prefijo de dirección para la subnet de Todos Container"
#   type        = string
#   default     = "10.0.8.0/24"
# }

# variable "frontend_container_subnet_prefix" {
#   description = "Prefijo de dirección para la subnet de Frontend Container"
#   type        = string
#   default     = "10.0.9.0/24"
# }

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

# Variables para imágenes Docker (para CI/CD)
variable "auth_api_image" {
  description = "Docker image for Auth API service"
  type        = string
  default     = "osgomez/auth-service:latest"
}

variable "users_api_image" {
  description = "Docker image for Users API service"
  type        = string
  default     = "osgomez/users-service:latest"
}

variable "todos_api_image" {
  description = "Docker image for Todos API service"
  type        = string
  default     = "osgomez/todos-service:latest"
}

variable "frontend_image" {
  description = "Docker image for Frontend service"
  type        = string
  default     = "osgomez/frontend:latest"
}

variable "log_processor_image" {
  description = "Docker image for Log Processor service"
  type        = string
  default     = "osgomez/log-message-processor:latest"
}


variable "client_id" {
  description = "Azure Service Principal Client ID"
  type        = string
  sensitive   = true
  default     = null
}

variable "client_secret" {
  description = "Azure Service Principal Client Secret"
  type        = string
  sensitive   = true
  default     = null
}

variable "tenant_id" {
  description = "Azure Tenant ID"
  type        = string
  default     = null
}

# Ya tenías esta, la dejamos por consistencia
variable "subscriptionId" {
  description = "Azure Subscription ID"
  type        = string
  default     = null
}

variable "dockerhub_username" {
  description = "Docker Hub username"
  type        = string
  sensitive   = true
}

variable "dockerhub_token" {
  description = "Docker Hub token"
  type        = string
  sensitive   = true
}
