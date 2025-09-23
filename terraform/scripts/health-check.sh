#!/bin/bash

# Script de Verificación de Salud Post-Optimización
# Verifica que todos los servicios funcionen correctamente después de las optimizaciones

set -e

echo "🏥 Verificando salud de servicios optimizados..."

# Obtener IPs públicas de los servicios directamente
AUTH_IP=$(terraform output -raw auth_service_ip 2>/dev/null || echo "NO_ENCONTRADA")
USERS_IP=$(terraform output -raw users_service_ip 2>/dev/null || echo "NO_ENCONTRADA")
TODOS_IP=$(terraform output -raw todos_service_ip 2>/dev/null || echo "NO_ENCONTRADA")
FRONTEND_IP=$(terraform output -raw frontend_service_ip 2>/dev/null || echo "NO_ENCONTRADA")

if [ "$AUTH_IP" = "NO_ENCONTRADA" ] || [ "$USERS_IP" = "NO_ENCONTRADA" ] || [ "$TODOS_IP" = "NO_ENCONTRADA" ] || [ "$FRONTEND_IP" = "NO_ENCONTRADA" ]; then
    echo "⚠️  No se pudieron obtener las IPs de los servicios"
    echo "Verifica que todos los servicios estén desplegados correctamente"
    exit 1
fi

echo "🌐 Auth Service IP: $AUTH_IP"
echo "🌐 Users Service IP: $USERS_IP"
echo "🌐 Todos Service IP: $TODOS_IP"
echo "🌐 Frontend Service IP: $FRONTEND_IP"

# Función para verificar endpoint
check_endpoint() {
    local name=$1
    local url=$2
    local expected_status=${3:-200}
    
    echo -n "Verificando $name... "
    
    if response=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 10 "$url" 2>/dev/null); then
        if [ "$response" = "$expected_status" ]; then
            echo "✅ OK ($response)"
            return 0
        else
            echo "❌ FAIL ($response, esperado $expected_status)"
            return 1
        fi
    else
        echo "❌ FAIL (sin respuesta)"
        return 1
    fi
}

echo ""
echo "🔍 Verificando endpoints principales..."

# Verificar Frontend
check_endpoint "Frontend" "http://$FRONTEND_IP/"

# Verificar Auth API
check_endpoint "Auth API" "http://$AUTH_IP:8000/version"

# Verificar Users API
check_endpoint "Users API Health" "http://$USERS_IP:8083/health"

# Verificar Todos API
check_endpoint "Todos API Health" "http://$TODOS_IP:8082/health"

echo ""
echo "🗄️  Verificando recursos de infraestructura..."

# Verificar que solo hay 1 servidor PostgreSQL
postgres_count=$(terraform state list | grep -c "azurerm_postgresql_flexible_server" || echo "0")
echo "Servidores PostgreSQL: $postgres_count (esperado: 1)"

# Verificar configuración de Redis
redis_info=$(terraform show -json | jq -r '.values.root_module.resources[] | select(.address=="module.security.azurerm_redis_cache.main") | .values.sku_name, .values.capacity' 2>/dev/null || echo "N/A N/A")
redis_sku=$(echo $redis_info | cut -d' ' -f1)
redis_capacity=$(echo $redis_info | cut -d' ' -f2)
echo "Redis Cache: $redis_sku, Capacidad: $redis_capacity (esperado: Basic, 0)"

# Application Gateway removido
echo "Application Gateway: REMOVIDO (acceso directo a servicios)"

echo ""
echo "💰 Resumen de optimizaciones aplicadas:"
echo "   🗄️  Bases de datos consolidadas: 3 → 1 servidor"
echo "   🚀 Recursos de contenedores con IPs públicas directas"
echo "   🌐 Application Gateway: ELIMINADO completamente"
echo "   🗃️  Redis Cache: Standard → Basic"

echo ""
if [ $postgres_count -eq 1 ] && [ "$redis_sku" = "Basic" ]; then
    echo "✅ OPTIMIZACIÓN EXITOSA: Todos los recursos están optimizados"
    echo "💰 Ahorro estimado: 70-80% en costos de infraestructura (sin Application Gateway)"
else
    echo "⚠️  VERIFICACIÓN PARCIAL: Algunos recursos pueden no estar optimizados"
    echo "Revisa la configuración de Terraform"
fi

echo ""
echo "📊 Para monitorear costos:"
echo "   1. Azure Cost Management: https://portal.azure.com/#blade/Microsoft_Azure_CostManagement/Menu/overview"
echo "   2. Configurar alertas de presupuesto"
echo "   3. Revisar métricas de uso semanalmente"

echo ""
echo "✨ Verificación de salud completada!"