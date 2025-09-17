#!/bin/bash

# Script de configuración rápida para el proyecto de microservicios
# Este script configura el entorno para el despliegue

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Configurando proyecto de microservicios...${NC}"

# Verificar que estamos en el directorio correcto
if [ ! -f "terraform/main.tf" ]; then
    echo -e "${RED}❌ Error: Ejecuta este script desde la raíz del proyecto${NC}"
    exit 1
fi

# Verificar que Terraform está instalado
if ! command -v terraform &> /dev/null; then
    echo -e "${RED}❌ Terraform no está instalado. Instálalo desde: https://www.terraform.io/downloads${NC}"
    exit 1
fi

# Verificar que Azure CLI está instalado
if ! command -v az &> /dev/null; then
    echo -e "${RED}❌ Azure CLI no está instalado. Instálalo desde: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Dependencias verificadas${NC}"

# Configurar archivo terraform.tfvars si no existe
if [ ! -f "terraform/terraform.tfvars" ]; then
    echo -e "${YELLOW}📝 Creando archivo terraform.tfvars...${NC}"
    cp terraform/terraform.tfvars.example terraform/terraform.tfvars
    echo -e "${GREEN}✅ Archivo terraform.tfvars creado${NC}"
    echo -e "${YELLOW}⚠️  Revisa y modifica terraform/terraform.tfvars si es necesario${NC}"
fi

# Inicializar Terraform
echo -e "${YELLOW}📦 Inicializando Terraform...${NC}"
cd terraform
terraform init
cd ..

echo -e "${GREEN}✅ Terraform inicializado${NC}"

# Validar configuración
echo -e "${YELLOW}✅ Validando configuración de Terraform...${NC}"
cd terraform
terraform validate
cd ..

echo -e "${GREEN}✅ Configuración validada${NC}"

# Mostrar próximos pasos
echo -e "${BLUE}🎯 Próximos pasos:${NC}"
echo ""
echo "1. Configura los secretos en GitHub Actions:"
echo "   - AZURE_CLIENT_ID"
echo "   - AZURE_CLIENT_SECRET"
echo "   - AZURE_TENANT_ID"
echo "   - AZURE_SUBSCRIPTION_ID"
echo ""
echo "2. Para desplegar localmente:"
echo "   cd terraform"
echo "   terraform plan"
echo "   terraform apply"
echo ""
echo "3. Para desplegar con GitHub Actions:"
echo "   git add ."
echo "   git commit -m 'Initial commit'"
echo "   git push origin main"
echo ""
echo -e "${GREEN}🎉 Configuración completada!${NC}"
