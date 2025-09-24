#!/bin/bash

# Script para iniciar todos los microservicios en modo desarrollo
# Autor: Generado para desarrollo local
# Fecha: $(date)

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}🚀 Iniciando Microservicios en Local${NC}"
echo -e "${BLUE}======================================${NC}"

# Función para verificar si Docker está ejecutándose
check_docker() {
    if ! docker info >/dev/null 2>&1; then
        echo -e "${RED}❌ Docker no está ejecutándose. Por favor inicia Docker primero.${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ Docker está ejecutándose${NC}"
}

# Función para verificar si docker-compose está disponible
check_docker_compose() {
    if ! command -v docker-compose >/dev/null 2>&1; then
        if ! docker compose version >/dev/null 2>&1; then
            echo -e "${RED}❌ docker-compose no está disponible${NC}"
            exit 1
        else
            DOCKER_COMPOSE_CMD="docker compose"
        fi
    else
        DOCKER_COMPOSE_CMD="docker-compose"
    fi
    echo -e "${GREEN}✅ docker-compose disponible: $DOCKER_COMPOSE_CMD${NC}"
}

# Función para limpiar contenedores anteriores
cleanup() {
    echo -e "${YELLOW}🧹 Limpiando contenedores anteriores...${NC}"
    $DOCKER_COMPOSE_CMD down --remove-orphans 2>/dev/null || true
    docker system prune -f --volumes 2>/dev/null || true
}

# Función para construir imágenes
build_images() {
    echo -e "${YELLOW}🔨 Construyendo imágenes de Docker...${NC}"
    $DOCKER_COMPOSE_CMD build --no-cache
}

# Función para iniciar servicios
start_services() {
    echo -e "${YELLOW}⚡ Iniciando servicios...${NC}"
    $DOCKER_COMPOSE_CMD up -d
}

# Función para mostrar logs
show_logs() {
    echo -e "${BLUE}📋 Mostrando logs de servicios...${NC}"
    sleep 5
    $DOCKER_COMPOSE_CMD logs --tail=20
}

# Función para mostrar el estado de los servicios
show_status() {
    echo -e "${BLUE}📊 Estado de servicios:${NC}"
    $DOCKER_COMPOSE_CMD ps
}

# Función para mostrar URLs de acceso
show_urls() {
    echo -e "${GREEN}======================================${NC}"
    echo -e "${GREEN}🎉 Servicios iniciados correctamente!${NC}"
    echo -e "${GREEN}======================================${NC}"
    echo ""
    echo -e "${BLUE}📱 URLs de acceso:${NC}"
    echo -e "  🌐 Frontend:           ${GREEN}http://localhost:3000${NC}"
    echo -e "  🔐 Auth API:           ${GREEN}http://localhost:8000${NC}"
    echo -e "  📝 Todos API:          ${GREEN}http://localhost:8082${NC}"
    echo -e "  👥 Users API:          ${GREEN}http://localhost:8083${NC}"
    echo ""
    echo -e "${BLUE}🛠️  Herramientas:${NC}"
    echo -e "  🐰 RabbitMQ Management: ${GREEN}http://localhost:15672${NC} (guest/guest)"
    echo -e "  🗄️  PostgreSQL:         ${GREEN}localhost:5432${NC} (postgres/postgres)"
    echo -e "  🔴 Redis:              ${GREEN}localhost:6379${NC}"
    echo ""
    echo -e "${YELLOW}💡 Comandos útiles:${NC}"
    echo -e "  Ver logs:              ${BLUE}./scripts/logs.sh${NC}"
    echo -e "  Detener servicios:     ${BLUE}./scripts/stop-dev.sh${NC}"
    echo -e "  Reiniciar servicios:   ${BLUE}./scripts/restart-dev.sh${NC}"
    echo -e "  Ver estado:            ${BLUE}docker-compose ps${NC}"
}

# Función principal
main() {
    # Verificaciones previas
    check_docker
    check_docker_compose

    # Manejo de argumentos
    if [[ "$1" == "--clean" ]]; then
        cleanup
    fi

    if [[ "$1" == "--build" ]] || [[ "$2" == "--build" ]]; then
        build_images
    fi

    # Iniciar servicios
    start_services

    # Esperar un poco para que los servicios se inicien
    echo -e "${YELLOW}⏳ Esperando que los servicios se inicien...${NC}"
    sleep 10

    # Mostrar estado y logs
    show_status
    show_logs

    # Mostrar URLs
    show_urls
}

# Manejo de señales para cleanup
trap 'echo -e "\n${YELLOW}Interrumpido por el usuario${NC}"; exit 1' INT TERM

# Verificar si estamos en el directorio correcto
if [[ ! -f "docker-compose.yml" ]]; then
    echo -e "${RED}❌ No se encontró docker-compose.yml. Ejecuta este script desde la raíz del proyecto.${NC}"
    exit 1
fi

# Ejecutar función principal
main "$@"