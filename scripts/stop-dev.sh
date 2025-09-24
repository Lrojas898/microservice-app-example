#!/bin/bash

# Script para detener todos los microservicios
# Autor: Generado para desarrollo local

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}🛑 Deteniendo Microservicios${NC}"
echo -e "${BLUE}======================================${NC}"

# Detectar comando docker-compose
if command -v docker-compose >/dev/null 2>&1; then
    DOCKER_COMPOSE_CMD="docker-compose"
elif docker compose version >/dev/null 2>&1; then
    DOCKER_COMPOSE_CMD="docker compose"
else
    echo -e "${RED}❌ docker-compose no está disponible${NC}"
    exit 1
fi

# Verificar si estamos en el directorio correcto
if [[ ! -f "docker-compose.yml" ]]; then
    echo -e "${RED}❌ No se encontró docker-compose.yml. Ejecuta este script desde la raíz del proyecto.${NC}"
    exit 1
fi

# Detener servicios
echo -e "${YELLOW}⏹️  Deteniendo servicios...${NC}"
$DOCKER_COMPOSE_CMD down

# Opción para limpiar volúmenes
if [[ "$1" == "--clean" ]]; then
    echo -e "${YELLOW}🧹 Limpiando volúmenes y datos...${NC}"
    $DOCKER_COMPOSE_CMD down --volumes --remove-orphans
    docker system prune -f
    echo -e "${GREEN}✅ Limpieza completada${NC}"
fi

echo -e "${GREEN}✅ Servicios detenidos correctamente${NC}"

# Mostrar comandos útiles
echo ""
echo -e "${YELLOW}💡 Para reiniciar:${NC}"
echo -e "  ${BLUE}./scripts/start-dev.sh${NC}"
echo ""
echo -e "${YELLOW}💡 Para limpiar todo (incluyendo datos):${NC}"
echo -e "  ${BLUE}./scripts/stop-dev.sh --clean${NC}"