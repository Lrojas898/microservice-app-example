#!/bin/bash

# Script de Rollback - Restaurar configuración anterior
# En caso de que las optimizaciones causen problemas

set -e

echo "🔄 Iniciando rollback a configuración anterior..."

# Verificar que existen backups
if [[ ! -f "databases.tf.backup" || ! -f "aci.tf.backup" || ! -f "modules/security/main.tf.backup" ]]; then
    echo "❌ Error: No se encontraron archivos de backup"
    echo "No se puede realizar rollback automático"
    exit 1
fi

echo "📦 Restaurando archivos de backup..."

# Restaurar archivos originales
mv databases.tf.backup databases.tf
mv aci.tf.backup aci.tf
mv modules/security/main.tf.backup modules/security/main.tf

# Limpiar archivos optimizados
rm -f databases-optimized.tf
rm -f aci-optimized.tf
rm -f modules/security/main-optimized.tf

echo "✅ Validando configuración restaurada..."
terraform validate

echo "📋 Generando plan de rollback..."
terraform plan -out=rollback-plan

echo "
🔄 ROLLBACK COMPLETADO

✅ Configuración anterior restaurada
✅ Archivos optimizados removidos
✅ Configuración validada

🔄 Para aplicar el rollback:
   terraform apply rollback-plan

⚠️  NOTA: Esto revertirá todos los cambios de optimización
   y restaurará los costos originales.
"

echo "✨ Rollback preparado exitosamente!"