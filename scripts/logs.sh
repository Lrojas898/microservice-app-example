#!/bin/bash

# Script para ver logs de los microservicios
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
    echo -e "${BLUE}📋 Uso del script de logs:${NC}"
    echo ""
    echo -e "${YELLOW}Opciones:${NC}"
    echo -e "  ${GREEN}./scripts/logs.sh${NC}                    - Logs de todos los servicios"
    echo -e "  ${GREEN}./scripts/logs.sh [servicio]${NC}         - Logs de un servicio específico"
    echo -e "  ${GREEN}./scripts/logs.sh -f${NC}                 - Seguir logs en tiempo real"
    echo -e "  ${GREEN}./scripts/logs.sh [servicio] -f${NC}      - Seguir logs de un servicio"
    echo -e "  ${GREEN}./scripts/logs.sh --tail=50${NC}          - Mostrar últimas 50 líneas"
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
    echo -e "  ${BLUE}./scripts/logs.sh auth-api${NC}           - Logs del servicio de autenticación"
    echo -e "  ${BLUE}./scripts/logs.sh users-api -f${NC}       - Seguir logs del servicio de usuarios"
    echo -e "  ${BLUE}./scripts/logs.sh --tail=100${NC}         - Últimas 100 líneas de todos los servicios"
}

# Parsear argumentos
SERVICE=""
FOLLOW=""
TAIL=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -f|--follow)
            FOLLOW="-f"
            shift
            ;;
        --tail=*)
            TAIL="--tail=${1#*=}"
            shift
            ;;
        --tail)
            TAIL="--tail=$2"
            shift 2
            ;;
        *)
            if [[ -z "$SERVICE" ]]; then
                SERVICE="$1"
            fi
            shift
            ;;
    esac
done

# Construir comando
CMD="$DOCKER_COMPOSE_CMD logs"

if [[ -n "$TAIL" ]]; then
    CMD="$CMD $TAIL"
fi

if [[ -n "$FOLLOW" ]]; then
    CMD="$CMD $FOLLOW"
fi

if [[ -n "$SERVICE" ]]; then
    CMD="$CMD $SERVICE"
    echo -e "${BLUE}📋 Mostrando logs de: ${GREEN}$SERVICE${NC}"
else
    echo -e "${BLUE}📋 Mostrando logs de todos los servicios${NC}"
fi

echo -e "${YELLOW}Comando: $CMD${NC}"
echo ""

# Ejecutar comando
$CMD