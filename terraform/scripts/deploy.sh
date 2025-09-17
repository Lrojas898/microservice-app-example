#!/bin/bash
set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}🚀 Iniciando despliegue de infraestructura...${NC}"

# Verificar que terraform está instalado
if ! command -v terraform &> /dev/null; then
    echo -e "${RED}❌ Terraform no está instalado${NC}"
    exit 1
fi

# Inicializar Terraform
echo -e "${YELLOW}📦 Inicializando Terraform...${NC}"
terraform init

# Validar configuración
echo -e "${YELLOW}✅ Validando configuración...${NC}"
terraform validate

# Formatear código
echo -e "${YELLOW}🎨 Formateando código...${NC}"
terraform fmt -recursive

# Crear plan
echo -e "${YELLOW}📋 Creando plan de despliegue...${NC}"
terraform plan -out=tfplan

# Aplicar cambios
echo -e "${YELLOW}🔧 Aplicando cambios...${NC}"
terraform apply -input=false -auto-approve tfplan

# Limpiar archivo de plan
rm -f tfplan

echo -e "${GREEN}✅ Infraestructura desplegada con éxito${NC}"