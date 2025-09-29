#!/bin/bash

# Script para liberar el lock de Terraform
# ⚠️  USAR CON CUIDADO - Solo si estás seguro que no hay otra ejecución activa

set -e

echo "🔒 Estado de lock de Terraform detectado"
echo ""
echo "Lock Info:"
echo "  ID: 844f5387-17b1-00a8-a801-e94785c6505a"
echo "  Path: tfstate/prod.terraform.tfstate"
echo "  Operation: OperationTypeApply"
echo "  Who: runner@runnervmf4ws1"
echo "  Created: 2025-09-22 12:20:34"
echo ""

read -p "¿Estás seguro que no hay otra ejecución de Terraform activa? (y/N): " confirm

if [[ $confirm =~ ^[Yy]$ ]]; then
    echo "🔓 Liberando lock forzadamente..."
    terraform force-unlock 844f5387-17b1-00a8-a801-e94785c6505a
    
    if [ $? -eq 0 ]; then
        echo "✅ Lock liberado exitosamente"
        echo ""
        echo "🔄 Ahora puedes ejecutar:"
        echo "   terraform plan"
        echo "   terraform apply"
    else
        echo "❌ Error al liberar el lock"
        echo "💡 Intenta:"
        echo "   1. Verificar que no hay GitHub Actions ejecutándose"
        echo "   2. Contactar al administrador del proyecto"
        echo "   3. Usar terraform apply -lock=false (NO recomendado)"
    fi
else
    echo "❌ Operación cancelada"
    echo ""
    echo "💡 Opciones alternativas:"
    echo "   1. Esperar a que termine la operación activa"
    echo "   2. Verificar GitHub Actions en el repositorio"
    echo "   3. Usar terraform apply -lock=false (riesgoso)"
fi