#!/bin/bash

# Script para reiniciar microservicios específicos o todos
# Autor: Generado para desarrollo local

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Función para mostrar ayuda
show_help() {
    echo -e "${BLUE}🔄 Uso del script de reinicio:${NC}"
    echo ""
    echo -e "${YELLOW}Opciones:${NC}"
    echo -e "  ${GREEN}./scripts/restart-dev.sh${NC}                    - Reiniciar todos los servicios"
    echo -e "  ${GREEN}./scripts/restart-dev.sh [servicio]${NC}         - Reiniciar un servicio específico"
    echo -e "  ${GREEN}./scripts/restart-dev.sh --build${NC}            - Reiniciar y reconstruir imágenes"
    echo ""
    echo -e "${YELLOW}Servicios disponibles:${NC}"
    echo -e "  • auth-api"
    echo -e "  • users-api"
    echo -e "  • todos-api"
    echo -e "  • frontend"
    echo -e "  • log-message-processor"
    echo -e "  • users-db"
    echo -e "  • redis"
    echo -e "  • rabbitmq"
    echo ""
    echo -e "${YELLOW}Ejemplos:${NC}"
    echo -e "  ${BLUE}./scripts/restart-dev.sh auth-api${NC}           - Reiniciar solo auth-api"
    echo -e "  ${BLUE}./scripts/restart-dev.sh frontend --build${NC}   - Reconstruir y reiniciar frontend"
}

# Parsear argumentos
SERVICE=""
BUILD=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        --build)
            BUILD="--build"
            shift
            ;;
        *)
            if [[ -z "$SERVICE" ]]; then
                SERVICE="$1"
            fi
            shift
            ;;
    esac
done

echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}🔄 Reiniciando Microservicios${NC}"
echo -e "${BLUE}======================================${NC}"

if [[ -n "$SERVICE" ]]; then
    echo -e "${YELLOW}🔄 Reiniciando servicio: ${GREEN}$SERVICE${NC}"

    if [[ -n "$BUILD" ]]; then
        echo -e "${YELLOW}🔨 Reconstruyendo imagen...${NC}"
        $DOCKER_COMPOSE_CMD build $SERVICE
    fi

    echo -e "${YELLOW}⏹️  Deteniendo $SERVICE...${NC}"
    $DOCKER_COMPOSE_CMD stop $SERVICE

    echo -e "${YELLOW}▶️  Iniciando $SERVICE...${NC}"
    $DOCKER_COMPOSE_CMD up -d $SERVICE

    echo -e "${GREEN}✅ $SERVICE reiniciado correctamente${NC}"

    # Mostrar logs del servicio reiniciado
    echo -e "${BLUE}📋 Logs recientes de $SERVICE:${NC}"
    sleep 2
    $DOCKER_COMPOSE_CMD logs --tail=10 $SERVICE

else
    echo -e "${YELLOW}🔄 Reiniciando todos los servicios...${NC}"

    if [[ -n "$BUILD" ]]; then
        echo -e "${YELLOW}🔨 Reconstruyendo todas las imágenes...${NC}"
        $DOCKER_COMPOSE_CMD build
    fi

    echo -e "${YELLOW}⏹️  Deteniendo servicios...${NC}"
    $DOCKER_COMPOSE_CMD down

    echo -e "${YELLOW}▶️  Iniciando servicios...${NC}"
    $DOCKER_COMPOSE_CMD up -d

    echo -e "${GREEN}✅ Todos los servicios reiniciados correctamente${NC}"

    # Esperar y mostrar estado
    echo -e "${YELLOW}⏳ Esperando que los servicios se inicien...${NC}"
    sleep 10

    echo -e "${BLUE}📊 Estado de servicios:${NC}"
    $DOCKER_COMPOSE_CMD ps
fi

echo ""
echo -e "${YELLOW}💡 Comandos útiles:${NC}"
echo -e "  Ver logs:              ${BLUE}./scripts/logs.sh${NC}"
echo -e "  Ver logs específicos:  ${BLUE}./scripts/logs.sh [servicio]${NC}"
echo -e "  Estado de servicios:   ${BLUE}docker-compose ps${NC}"