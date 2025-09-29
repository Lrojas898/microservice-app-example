#!/bin/bash

# Script de monitoreo durante deploy para detectar cuellos de botella

echo "🔍 Monitoreando deploy en tiempo real..."

# Función para mostrar estado de containers
monitor_containers() {
    echo "📊 Estado actual de containers:"
    az container list --resource-group microservice-app-rg --output table --query "[].{Name:name,State:containers[0].instanceView.currentState.state,IP:ipAddress.ip}" 2>/dev/null || echo "ℹ️ Containers aún no creados"
}

# Función para mostrar estado de infraestructura
monitor_infrastructure() {
    echo "🏗️ Estado de infraestructura:"
    echo "  PostgreSQL:" $(az postgres flexible-server list --resource-group microservice-app-rg --query "[0].state" -o tsv 2>/dev/null || echo "No creado")
    echo "  Redis:" $(az redis list --resource-group microservice-app-rg --query "[0].provisioningState" -o tsv 2>/dev/null || echo "No creado")
}

# Función para mostrar progreso de terraform
monitor_terraform() {
    if [ -f terraform.tfstate ]; then
        echo "📈 Recursos creados:"
        grep -o '"type":"[^"]*"' terraform.tfstate | sort | uniq -c | head -10
    fi
}

# Loop de monitoreo
while true; do
    clear
    echo "=== 🚀 Monitor de Deploy Azure ==="
    echo "Tiempo: $(date)"
    echo ""

    monitor_terraform
    echo ""
    monitor_infrastructure
    echo ""
    monitor_containers
    echo ""

    # Verificar si el deploy terminó
    if az container show --name auth-service --resource-group microservice-app-rg &>/dev/null; then
        if az container show --name frontend-service --resource-group microservice-app-rg &>/dev/null; then
            echo "✅ Deploy completado!"
            break
        fi
    fi

    echo "⏳ Esperando... (Ctrl+C para salir)"
    sleep 10
done

echo ""
echo "🎉 Deploy finalizado!"
echo "🌐 URLs disponibles:"
az container list --resource-group microservice-app-rg --output table --query "[?ipAddress.ip].{Service:name,URL:join('', ['http://', ipAddress.ip, ':', containers[0].ports[0].port])}"