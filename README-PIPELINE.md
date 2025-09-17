# 🚀 Microservice App - Pipeline de Infraestructura

## 📋 Descripción del Proyecto

Este proyecto implementa un pipeline de infraestructura automatizada para una aplicación de microservicios usando **Terraform** y **GitHub Actions**.

## 🏗️ Arquitectura

### Estrategia de Branching
- **Desarrollo**: Trunk-based development (rama `main`)
- **Operaciones**: GitHub Flow adaptado (rama `main` para producción)

### Componentes de la Infraestructura
- **Resource Group**: `microservice-app-rg`
- **Virtual Network**: Con subnets para cada microservicio
- **Bases de Datos**: 3 PostgreSQL Flexible Servers (Auth, Users, Todos)
- **Cache**: Azure Redis Cache
- **Monitoring**: Application Insights
- **Security**: Key Vault para secretos

## 🛠️ Tecnologías Utilizadas

- **Terraform**: Infraestructura como código
- **GitHub Actions**: CI/CD Pipeline
- **Azure**: Cloud provider
- **Docker**: Containerización de microservicios

## 🚀 Configuración Rápida

### 1. Configurar Secretos en GitHub

Ve a `Settings > Secrets and variables > Actions` y añade:

```
AZURE_CLIENT_ID=tu_client_id
AZURE_CLIENT_SECRET=tu_client_secret
AZURE_TENANT_ID=tu_tenant_id
AZURE_SUBSCRIPTION_ID=tu_subscription_id
```

### 2. Configurar Variables de Terraform

Copia el archivo de ejemplo:
```bash
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
```

Edita `terraform.tfvars` con tus valores:
```hcl
resource_group_name = "microservice-app-rg"
location = "eastus"
```

### 3. Desplegar Infraestructura

#### Opción A: Usando GitHub Actions (Recomendado)
1. Haz push a la rama `main`
2. El pipeline se ejecutará automáticamente
3. Revisa los logs en `Actions`

#### Opción B: Despliegue Local
```bash
cd terraform
terraform init
terraform plan
terraform apply
```

## 📁 Estructura del Proyecto

```
microservice-app-example/
├── .github/
│   └── workflows/
│       └── main-pipeline.yml          # Pipeline principal
├── terraform/
│   ├── main.tf                        # Configuración principal
│   ├── variables.tf                   # Variables
│   ├── databases.tf                   # Bases de datos
│   ├── modules/                       # Módulos reutilizables
│   └── scripts/                       # Scripts de automatización
├── auth-api/                          # Microservicio de autenticación
├── users-api/                         # Microservicio de usuarios
├── todos-api/                         # Microservicio de tareas
├── frontend/                          # Aplicación frontend
└── log-message-processor/             # Procesador de logs
```

## 🔧 Comandos Útiles

### Terraform
```bash
# Inicializar
terraform init

# Validar
terraform validate

# Formatear código
terraform fmt -recursive

# Crear plan
terraform plan

# Aplicar cambios
terraform apply

# Destruir infraestructura
terraform destroy
```

### Scripts de Automatización
```bash
# Desplegar
./terraform/scripts/deploy.sh

# Destruir
./terraform/scripts/destroy.sh
```

## 🎯 Patrones de Diseño Implementados

1. **Cache Aside**: Redis Cache para el microservicio de Todos
2. **Circuit Breaker**: Implementado en el procesador de logs

## 📊 Monitoreo

- **Application Insights**: Monitoreo de aplicaciones
- **Logs**: Procesamiento centralizado de logs
- **Health Checks**: Verificación de estado de servicios

## 🚨 Solución de Problemas

### Error de Ubicación Restringida
Si encuentras el error `LocationIsOfferRestricted`:
1. Cambia la región en `variables.tf` de `westus2` a `eastus`
2. Actualiza `terraform.tfvars` con la nueva región

### Error de Permisos
Asegúrate de que tu service principal tenga los permisos necesarios:
- Contributor en el Resource Group
- Access to Azure Container Registry (si usas ACR)

## 📝 Notas de Entrega

- ✅ Pipeline de CI/CD funcional
- ✅ Infraestructura como código con Terraform
- ✅ Estrategia de branching definida
- ✅ Patrones de diseño implementados
- ✅ Documentación completa
- ✅ Scripts de automatización

## 🔗 Enlaces Útiles

- [Documentación de Terraform](https://www.terraform.io/docs)
- [GitHub Actions](https://docs.github.com/en/actions)
- [Azure Provider para Terraform](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
