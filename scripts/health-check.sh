#!/bin/bash

# Script para verificar el estado de salud de todos los microservicios
# Autor: Generado para desarrollo local

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}🏥 Health Check de Microservicios${NC}"
echo -e "${BLUE}======================================${NC}"

# Función para verificar endpoint HTTP
check_http() {
    local name=$1
    local url=$2
    local expected_code=${3:-200}

    echo -n -e "${YELLOW}Verificando $name...${NC} "

    if command -v curl >/dev/null 2>&1; then
        if response=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "$url" 2>/dev/null); then
            if [[ "$response" == "$expected_code" ]]; then
                echo -e "${GREEN}✅ OK (HTTP $response)${NC}"
                return 0
            else
                echo -e "${RED}❌ FAIL (HTTP $response)${NC}"
                return 1
            fi
        else
            echo -e "${RED}❌ FAIL (No response)${NC}"
            return 1
        fi
    elif command -v wget >/dev/null 2>&1; then
        if wget -q --spider --timeout=10 "$url" 2>/dev/null; then
            echo -e "${GREEN}✅ OK${NC}"
            return 0
        else
            echo -e "${RED}❌ FAIL${NC}"
            return 1
        fi
    else
        echo -e "${YELLOW}⚠️  SKIP (curl/wget no disponible)${NC}"
        return 0
    fi
}

# Función para verificar puerto TCP
check_port() {
    local name=$1
    local host=$2
    local port=$3

    echo -n -e "${YELLOW}Verificando $name...${NC} "

    if command -v nc >/dev/null 2>&1; then
        if nc -z "$host" "$port" 2>/dev/null; then
            echo -e "${GREEN}✅ OK${NC}"
            return 0
        else
            echo -e "${RED}❌ FAIL${NC}"
            return 1
        fi
    elif command -v telnet >/dev/null 2>&1; then
        if timeout 5 telnet "$host" "$port" </dev/null 2>/dev/null | grep -q "Connected"; then
            echo -e "${GREEN}✅ OK${NC}"
            return 0
        else
            echo -e "${RED}❌ FAIL${NC}"
            return 1
        fi
    else
        echo -e "${YELLOW}⚠️  SKIP (nc/telnet no disponible)${NC}"
        return 0
    fi
}

# Función para verificar estado de contenedor Docker
check_container() {
    local name=$1
    local container_name=$2

    echo -n -e "${YELLOW}Verificando $name container...${NC} "

    if command -v docker >/dev/null 2>&1; then
        if docker ps --format "table {{.Names}}\t{{.Status}}" | grep -q "$container_name.*Up"; then
            echo -e "${GREEN}✅ OK (Running)${NC}"
            return 0
        elif docker ps -a --format "table {{.Names}}\t{{.Status}}" | grep -q "$container_name"; then
            echo -e "${RED}❌ FAIL (Not running)${NC}"
            return 1
        else
            echo -e "${RED}❌ FAIL (Not found)${NC}"
            return 1
        fi
    else
        echo -e "${YELLOW}⚠️  SKIP (Docker no disponible)${NC}"
        return 0
    fi
}

# Contadores para resumen
total_checks=0
passed_checks=0

# Función para ejecutar check y contar resultado
run_check() {
    total_checks=$((total_checks + 1))
    if "$@"; then
        passed_checks=$((passed_checks + 1))
    fi
}

echo -e "${BLUE}🐳 Estado de Contenedores:${NC}"
run_check check_container "Auth API" "auth-api"
run_check check_container "Users API" "users-api"
run_check check_container "Todos API" "todos-api"
run_check check_container "Frontend" "frontend"
run_check check_container "Log Processor" "log-message-processor"
run_check check_container "PostgreSQL" "users-db"
run_check check_container "Redis" "redis"
run_check check_container "RabbitMQ" "rabbitmq"

echo ""
echo -e "${BLUE}🌐 APIs y Servicios Web:${NC}"
run_check check_http "Auth API Health" "http://localhost:8000/health"
run_check check_http "Users API Health" "http://localhost:8083/actuator/health"
run_check check_http "Todos API" "http://localhost:8082/todos"
run_check check_http "Frontend" "http://localhost:3000"
run_check check_http "RabbitMQ Management" "http://localhost:15672"

echo ""
echo -e "${BLUE}🔌 Puertos de Infraestructura:${NC}"
run_check check_port "PostgreSQL" "localhost" "5432"
run_check check_port "Redis" "localhost" "6379"
run_check check_port "RabbitMQ AMQP" "localhost" "5672"

echo ""
echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}📊 Resumen de Health Check${NC}"
echo -e "${BLUE}======================================${NC}"

if [[ $passed_checks -eq $total_checks ]]; then
    echo -e "${GREEN}✅ Todos los checks pasaron ($passed_checks/$total_checks)${NC}"
    echo -e "${GREEN}🎉 Sistema completamente operativo!${NC}"
    exit_code=0
else
    failed_checks=$((total_checks - passed_checks))
    echo -e "${RED}❌ $failed_checks checks fallaron ($passed_checks/$total_checks pasaron)${NC}"
    echo -e "${YELLOW}⚠️  Revisa los servicios que fallaron arriba${NC}"
    exit_code=1
fi

echo ""
echo -e "${BLUE}💡 URLs de acceso:${NC}"
echo -e "  🌐 Frontend:           ${GREEN}http://localhost:3000${NC}"
echo -e "  🔐 Auth API:           ${GREEN}http://localhost:8000${NC}"
echo -e "  📝 Todos API:          ${GREEN}http://localhost:8082${NC}"
echo -e "  👥 Users API:          ${GREEN}http://localhost:8083${NC}"
echo -e "  🐰 RabbitMQ:           ${GREEN}http://localhost:15672${NC}"

echo ""
echo -e "${YELLOW}💡 Para más información:${NC}"
echo -e "  Ver logs:              ${BLUE}./scripts/logs.sh${NC}"
echo -e "  Estado de servicios:   ${BLUE}docker-compose ps${NC}"
echo -e "  Reiniciar servicios:   ${BLUE}./scripts/restart-dev.sh${NC}"

exit $exit_code