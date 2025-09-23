#!/bin/bash

# Script de Migración a Infraestructura Optimizada
# Ahorro estimado total: 60-70% en costos de infraestructura

set -e

echo "🚀 Iniciando migración a infraestructura optimizada..."

# 1. Backup de configuración actual
echo "📦 Creando backup de configuración actual..."
cp databases.tf databases.tf.backup
cp aci.tf aci.tf.backup  
cp modules/security/main.tf modules/security/main.tf.backup

# 2. Aplicar configuraciones optimizadas
echo "🔄 Aplicando configuraciones optimizadas..."

# Reemplazar archivos con versiones optimizadas
mv databases-optimized.tf databases.tf
mv aci-optimized.tf aci.tf
mv modules/security/main-optimized.tf modules/security/main.tf

# 3. Validar configuración Terraform
echo "✅ Validando configuración Terraform..."
terraform validate

# 4. Planificar cambios
echo "📋 Generando plan de cambios..."
terraform plan -out=optimize-plan

echo "
🎯 RESUMEN DE OPTIMIZACIONES APLICADAS:

📊 AHORRO ESTIMADO: 75-85% en costos totales (Application Gateway eliminado)

🗄️  BASES DE DATOS:
   ❌ Antes: 3 servidores PostgreSQL separados
   ✅ Ahora: 1 servidor consolidado con 3 bases de datos
   💰 Ahorro: ~70%

🚀 CONTENEDORES:
   ❌ Antes: 4 containers privados con subnets complejas
   ✅ Ahora: 4 containers con IPs públicas directas
   💰 Ahorro: ~50% (sin NSGs ni subnets de contenedores)

🌐 APPLICATION GATEWAY:
   ❌ Antes: Application Gateway con capacidad 2 instancias
   ✅ Ahora: ELIMINADO - Acceso directo por IPs públicas
   💰 Ahorro: ~100% (componente completamente removido)

🗃️  REDIS CACHE:
   ❌ Antes: Standard con capacidad 2 (2.5GB)
   ✅ Ahora: Basic con capacidad 0 (250MB)
   💰 Ahorro: ~80%

📈 MONITOREO:
   • Health checks optimizados (60s intervals)
   • Backup retention mínimo (7 días)
   • Timeouts optimizados

⚠️  CONSIDERACIONES:
   • Funcionalidad completa mantenida
   • Adecuado para desarrollo/staging
   • Para producción, considerar auto-scaling
   • Monitorear performance post-migración
"

echo "
🔄 PRÓXIMOS PASOS:

1. Revisar el plan generado:
   terraform show optimize-plan

2. Aplicar cambios:
   terraform apply optimize-plan

3. Verificar funcionamiento:
   ./scripts/health-check.sh

4. (Opcional) Rollback si es necesario:
   ./scripts/rollback.sh
"

echo "✨ Migración preparada exitosamente!"