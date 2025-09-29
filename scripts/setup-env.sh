#!/bin/bash

# Script para configurar el entorno de desarrollo local
# Autor: Generado para desarrollo local

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}⚙️  Configuración del Entorno de Desarrollo${NC}"
echo -e "${BLUE}======================================${NC}"

# Función para verificar si un comando existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Función para verificar versión de Docker
check_docker() {
    echo -n -e "${YELLOW}Verificando Docker...${NC} "
    if command_exists docker; then
        docker_version=$(docker --version | cut -d ' ' -f3 | cut -d ',' -f1)
        echo -e "${GREEN}✅ Docker $docker_version${NC}"

        # Verificar que Docker esté ejecutándose
        if docker info >/dev/null 2>&1; then
            echo -e "${GREEN}✅ Docker daemon está ejecutándose${NC}"
        else
            echo -e "${RED}❌ Docker daemon no está ejecutándose${NC}"
            echo -e "${YELLOW}💡 Inicia Docker Desktop o el servicio de Docker${NC}"
            return 1
        fi
    else
        echo -e "${RED}❌ Docker no está instalado${NC}"
        echo -e "${YELLOW}💡 Instala Docker desde: https://docs.docker.com/get-docker/${NC}"
        return 1
    fi
}

# Función para verificar Docker Compose
check_docker_compose() {
    echo -n -e "${YELLOW}Verificando Docker Compose...${NC} "
    if command_exists docker-compose; then
        compose_version=$(docker-compose --version | cut -d ' ' -f3 | cut -d ',' -f1)
        echo -e "${GREEN}✅ docker-compose $compose_version${NC}"
    elif docker compose version >/dev/null 2>&1; then
        compose_version=$(docker compose version --short)
        echo -e "${GREEN}✅ docker compose $compose_version${NC}"
    else
        echo -e "${RED}❌ Docker Compose no está instalado${NC}"
        echo -e "${YELLOW}💡 Instala Docker Compose o actualiza Docker Desktop${NC}"
        return 1
    fi
}

# Función para verificar herramientas útiles
check_tools() {
    echo -e "${BLUE}🛠️  Verificando herramientas opcionales:${NC}"

    tools=("curl" "wget" "nc" "git" "node" "npm" "mvn" "java" "go" "python3")

    for tool in "${tools[@]}"; do
        echo -n -e "${YELLOW}  $tool...${NC} "
        if command_exists "$tool"; then
            case $tool in
                node)
                    version=$(node --version)
                    echo -e "${GREEN}✅ $version${NC}"
                    ;;
                npm)
                    version=$(npm --version)
                    echo -e "${GREEN}✅ v$version${NC}"
                    ;;
                java)
                    version=$(java -version 2>&1 | head -n 1 | cut -d '"' -f 2)
                    echo -e "${GREEN}✅ $version${NC}"
                    ;;
                mvn)
                    version=$(mvn --version 2>/dev/null | head -n 1 | cut -d ' ' -f 3)
                    echo -e "${GREEN}✅ $version${NC}"
                    ;;
                go)
                    version=$(go version | cut -d ' ' -f 3)
                    echo -e "${GREEN}✅ $version${NC}"
                    ;;
                python3)
                    version=$(python3 --version | cut -d ' ' -f 2)
                    echo -e "${GREEN}✅ $version${NC}"
                    ;;
                *)
                    echo -e "${GREEN}✅ Instalado${NC}"
                    ;;
            esac
        else
            echo -e "${YELLOW}⚠️  No instalado${NC}"
        fi
    done
}

# Función para hacer ejecutables los scripts
make_scripts_executable() {
    echo -e "${BLUE}🔧 Configurando permisos de scripts...${NC}"

    scripts_dir="./scripts"
    if [[ -d "$scripts_dir" ]]; then
        chmod +x "$scripts_dir"/*.sh
        echo -e "${GREEN}✅ Scripts configurados como ejecutables${NC}"
    else
        echo -e "${YELLOW}⚠️  Directorio de scripts no encontrado${NC}"
    fi
}

# Función para crear archivo .env de ejemplo
create_env_example() {
    echo -e "${BLUE}📄 Creando archivo .env.example...${NC}"

    cat > .env.example << 'EOF'
# Configuración para desarrollo local
# Copia este archivo a .env y ajusta los valores según necesites

# Auth API
AUTH_API_PORT=8000
AUTH_API_URL=http://localhost:8000

# Users API
USERS_API_PORT=8083
USERS_API_URL=http://localhost:8083
SPRING_PROFILES_ACTIVE=docker

# Todos API
TODOS_API_PORT=8082
TODOS_API_URL=http://localhost:8082
NODE_ENV=development

# Frontend
FRONTEND_PORT=3000
AUTH_API_ADDRESS=http://localhost:8000
TODOS_API_ADDRESS=http://localhost:8082
USERS_API_ADDRESS=http://localhost:8083

# Database
POSTGRES_DB=usersdb
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
POSTGRES_PORT=5432

# Redis
REDIS_PORT=6379
REDIS_URL=redis://localhost:6379

# RabbitMQ
RABBITMQ_PORT=5672
RABBITMQ_MANAGEMENT_PORT=15672
RABBITMQ_DEFAULT_USER=guest
RABBITMQ_DEFAULT_PASS=guest
RABBITMQ_URL=amqp://guest:guest@localhost:5672/

# Log Level
LOG_LEVEL=INFO
EOF

    echo -e "${GREEN}✅ Archivo .env.example creado${NC}"
    echo -e "${YELLOW}💡 Copia .env.example a .env y ajusta los valores si es necesario${NC}"
}

# Función para verificar puertos disponibles
check_ports() {
    echo -e "${BLUE}🔌 Verificando puertos disponibles...${NC}"

    ports=(3000 5432 5672 6379 8000 8082 8083 15672)
    port_names=("Frontend" "PostgreSQL" "RabbitMQ" "Redis" "Auth API" "Todos API" "Users API" "RabbitMQ Management")

    for i in "${!ports[@]}"; do
        port=${ports[$i]}
        name=${port_names[$i]}

        echo -n -e "${YELLOW}  Puerto $port ($name)...${NC} "

        if command_exists nc; then
            if nc -z localhost "$port" 2>/dev/null; then
                echo -e "${RED}❌ En uso${NC}"
            else
                echo -e "${GREEN}✅ Disponible${NC}"
            fi
        elif command_exists lsof; then
            if lsof -i ":$port" >/dev/null 2>&1; then
                echo -e "${RED}❌ En uso${NC}"
            else
                echo -e "${GREEN}✅ Disponible${NC}"
            fi
        else
            echo -e "${YELLOW}⚠️  No se pudo verificar${NC}"
        fi
    done
}

# Función para mostrar información del sistema
show_system_info() {
    echo -e "${BLUE}💻 Información del sistema:${NC}"
    echo -e "  OS: $(uname -s) $(uname -r)"
    echo -e "  Arquitectura: $(uname -m)"

    if command_exists free; then
        memory=$(free -h | awk '/^Mem:/ {print $2}')
        echo -e "  Memoria total: $memory"
    fi

    if command_exists df; then
        disk=$(df -h . | awk 'NR==2 {print $4}')
        echo -e "  Espacio disponible: $disk"
    fi
}

# Función para mostrar resumen final
show_summary() {
    echo ""
    echo -e "${BLUE}======================================${NC}"
    echo -e "${BLUE}📋 Resumen de Configuración${NC}"
    echo -e "${BLUE}======================================${NC}"
    echo ""
    echo -e "${GREEN}✅ Entorno configurado correctamente${NC}"
    echo ""
    echo -e "${YELLOW}💡 Próximos pasos:${NC}"
    echo -e "  1. ${BLUE}./scripts/start-dev.sh${NC}           - Iniciar todos los servicios"
    echo -e "  2. ${BLUE}./scripts/health-check.sh${NC}        - Verificar estado de servicios"
    echo -e "  3. ${BLUE}./scripts/logs.sh${NC}                - Ver logs de servicios"
    echo ""
    echo -e "${YELLOW}📚 Scripts disponibles:${NC}"
    echo -e "  • ${BLUE}start-dev.sh${NC}       - Iniciar servicios"
    echo -e "  • ${BLUE}stop-dev.sh${NC}        - Detener servicios"
    echo -e "  • ${BLUE}restart-dev.sh${NC}     - Reiniciar servicios"
    echo -e "  • ${BLUE}logs.sh${NC}            - Ver logs"
    echo -e "  • ${BLUE}health-check.sh${NC}    - Verificar estado"
    echo ""
    echo -e "${YELLOW}🌐 URLs después de iniciar:${NC}"
    echo -e "  • Frontend:           http://localhost:3000"
    echo -e "  • Auth API:           http://localhost:8000"
    echo -e "  • Todos API:          http://localhost:8082"
    echo -e "  • Users API:          http://localhost:8083"
    echo -e "  • RabbitMQ:           http://localhost:15672"
}

# Función principal
main() {
    # Verificar directorio
    if [[ ! -f "docker-compose.yml" ]]; then
        echo -e "${RED}❌ No se encontró docker-compose.yml. Ejecuta este script desde la raíz del proyecto.${NC}"
        exit 1
    fi

    # Mostrar información del sistema
    show_system_info
    echo ""

    # Verificar requisitos principales
    if ! check_docker || ! check_docker_compose; then
        echo -e "${RED}❌ Faltan requisitos principales. Instala Docker y Docker Compose primero.${NC}"
        exit 1
    fi

    echo ""

    # Verificar herramientas opcionales
    check_tools
    echo ""

    # Verificar puertos
    check_ports
    echo ""

    # Configurar scripts
    make_scripts_executable

    # Crear archivo de ejemplo de variables de entorno
    create_env_example

    # Mostrar resumen
    show_summary
}

# Verificar si estamos en el directorio correcto
if [[ ! -f "docker-compose.yml" ]]; then
    echo -e "${RED}❌ No se encontró docker-compose.yml. Ejecuta este script desde la raíz del proyecto.${NC}"
    exit 1
fi

# Ejecutar función principal
main "$@"