#!/bin/bash

# Zipkin VM Startup Script - ULTRA OPTIMIZADO para velocidad máxima
set -e

echo "🚀 Iniciando configuración ultra-rápida de Zipkin..."

# Actualizar sistema en background (no bloquear)
apt-get update &
UPDATE_PID=$!

# Instalar Java 11 (más liviano que Java 17 para Zipkin)
echo "📦 Instalando OpenJDK 11..."
apt-get install -y openjdk-11-jre-headless curl wget htop &
JAVA_PID=$!

# Esperar solo a Java (crítico para Zipkin)
wait $JAVA_PID

# Verificar Java
java -version

# Crear usuario zipkin (seguridad)
echo "👤 Creando usuario zipkin..."
useradd -r -m -s /bin/bash zipkin

# Descargar Zipkin slim (más rápido que build)
echo "⬇️ Descargando Zipkin 2.24..."
cd /opt
wget -O zipkin.jar "https://search.maven.org/remote_content?g=io.zipkin&a=zipkin-server&v=2.24&c=slim"

# Configurar permisos
chown zipkin:zipkin zipkin.jar
chmod +x zipkin.jar

# Crear script de inicio ultra-optimizado
cat > /opt/start-zipkin.sh << 'EOF'
#!/bin/bash

# Variables de entorno para máxima velocidad
export STORAGE_TYPE=mem
export QUERY_ENABLED=true
export SEARCH_ENABLED=false
export SELF_TRACING_ENABLED=false
export LOGGING_LEVEL_ROOT=ERROR
export ZIPKIN_STORAGE_MEM_MAX_SPANS=5000

# JVM OPTIMIZADA para VM de 1GB RAM - configuración económica
export JAVA_OPTS="-server \
  -Xms32m -Xmx128m \
  -XX:+UseSerialGC \
  -XX:TieredStopAtLevel=1 \
  -XX:MaxMetaspaceSize=32m \
  -XX:CompressedClassSpaceSize=8m \
  -XX:+ExitOnOutOfMemoryError \
  -Djava.security.egd=file:/dev/./urandom \
  -Djava.awt.headless=true \
  -Dfile.encoding=UTF-8 \
  -Duser.timezone=UTC"

# Ejecutar Zipkin
echo "🏃 Iniciando Zipkin con configuración ultra-optimizada..."
exec java $JAVA_OPTS -jar /opt/zipkin.jar
EOF

chmod +x /opt/start-zipkin.sh
chown zipkin:zipkin /opt/start-zipkin.sh

# Crear servicio systemd para auto-start
cat > /etc/systemd/system/zipkin.service << 'EOF'
[Unit]
Description=Zipkin Server
After=network.target

[Service]
Type=exec
User=zipkin
Group=zipkin
ExecStart=/opt/start-zipkin.sh
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal
SyslogIdentifier=zipkin

# Límites de recursos (seguridad)
LimitNOFILE=65536
LimitNPROC=4096

[Install]
WantedBy=multi-user.target
EOF

# Optimizaciones del sistema para velocidad
echo "⚡ Aplicando optimizaciones del sistema..."

# Optimizar kernel para networking rápido
cat >> /etc/sysctl.conf << 'EOF'

# Optimizaciones para Zipkin (networking rápido)
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
net.core.netdev_max_backlog = 5000
net.ipv4.tcp_congestion_control = bbr
EOF

sysctl -p

# Configurar swap mínimo (mejor para Java)
echo 'vm.swappiness=1' >> /etc/sysctl.conf

# Habilitar y iniciar servicio
systemctl daemon-reload
systemctl enable zipkin
systemctl start zipkin

# Esperar a que termine la actualización del sistema
wait $UPDATE_PID || true

# Health check rápido
echo "🔍 Verificando que Zipkin esté funcionando..."
sleep 10

# Verificar que el servicio esté corriendo
if systemctl is-active --quiet zipkin; then
    echo "✅ Zipkin está corriendo correctamente!"

    # Intentar health check HTTP
    for i in {1..30}; do
        if curl -f http://localhost:9411/health 2>/dev/null; then
            echo "✅ Zipkin health check exitoso!"
            break
        fi
        echo "⏳ Esperando Zipkin... intento $i/30"
        sleep 2
    done
else
    echo "❌ Error: Zipkin no está corriendo"
    systemctl status zipkin
    journalctl -u zipkin --no-pager -l
fi

echo "🎉 Configuración de Zipkin VM completada!"
echo "🌐 Zipkin disponible en: http://$(curl -s ifconfig.me):9411"

# Limpiar archivos temporales para liberar espacio
apt-get clean
rm -rf /var/lib/apt/lists/*

echo "📊 Estado final del sistema:"
free -h
df -h
systemctl status zipkin --no-pager