#!/bin/bash
set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}⚠️  ADVERTENCIA: Estás a punto de eliminar toda la infraestructura${NC}"
echo -e "${YELLOW}📋 Recursos que serán eliminados:${NC}"
echo "   - Resource Group: microservice-app-rg"
echo "   - Virtual Network y subnets"
echo "   - PostgreSQL Flexible Servers (3)"
echo "   - Key Vault"
echo "   - Application Gateway"
echo "   - Redis Cache"
echo "   - Application Insights"
echo ""

# Confirmación del usuario
read -p "¿Estás seguro de que quieres continuar? (escribe 'yes' para confirmar): " confirmation

if [ "$confirmation" != "yes" ]; then
    echo -e "${RED}❌ Operación cancelada${NC}"
    exit 1
fi

echo -e "${YELLOW}🗑️  Eliminando infraestructura...${NC}"

# Inicializar si es necesario
terraform init

# Eliminar infraestructura
terraform destroy -auto-approve

echo -e "${GREEN}✅ Infraestructura eliminada con éxito${NC}"