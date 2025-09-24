# 🐳 Guía de Docker para Microservicios

Esta guía te ayudará a ejecutar todos los microservicios localmente usando Docker y docker-compose.

## 📋 Requisitos Previos

- Docker 20.x o superior
- Docker Compose 2.x o superior
- 8GB de RAM disponible (recomendado)
- Puertos disponibles: 3000, 5432, 5672, 6379, 8000, 8082, 8083, 15672

## 🚀 Inicio Rápido

1. **Configurar el entorno:**
   ```bash
   ./scripts/setup-env.sh
   ```

2. **Iniciar todos los servicios:**
   ```bash
   ./scripts/start-dev.sh
   ```

3. **Verificar que todo esté funcionando:**
   ```bash
   ./scripts/health-check.sh
   ```

## 🏗️ Arquitectura de Servicios

### Microservicios

| Servicio | Puerto | Tecnología | Descripción |
|----------|--------|------------|-------------|
| **Frontend** | 3000 | Vue.js/React + Nginx | Interfaz de usuario |
| **Auth API** | 8000 | Go | Servicio de autenticación |
| **Users API** | 8083 | Java Spring Boot | Gestión de usuarios |
| **Todos API** | 8082 | Node.js | Gestión de tareas |
| **Log Processor** | - | Python | Procesador de logs |

### Infraestructura

| Servicio | Puerto | Descripción |
|----------|--------|-------------|
| **PostgreSQL** | 5432 | Base de datos principal |
| **Redis** | 6379 | Caché y sesiones |
| **RabbitMQ** | 5672/15672 | Cola de mensajes |

## 📜 Scripts Disponibles

### Principales
- `./scripts/start-dev.sh` - Iniciar todos los servicios
- `./scripts/stop-dev.sh` - Detener todos los servicios
- `./scripts/restart-dev.sh` - Reiniciar servicios
- `./scripts/health-check.sh` - Verificar estado de servicios

### Utilidades
- `./scripts/logs.sh` - Ver logs de servicios
- `./scripts/setup-env.sh` - Configurar entorno

### Ejemplos de Uso

```bash
# Iniciar con reconstrucción de imágenes
./scripts/start-dev.sh --build

# Reiniciar solo un servicio
./scripts/restart-dev.sh auth-api

# Ver logs de un servicio específico
./scripts/logs.sh users-api -f

# Detener y limpiar todo
./scripts/stop-dev.sh --clean
```

## 🌐 URLs de Acceso

Una vez iniciados los servicios:

- **Frontend:** http://localhost:3000
- **Auth API:** http://localhost:8000
- **Users API:** http://localhost:8083
- **Todos API:** http://localhost:8082
- **RabbitMQ Management:** http://localhost:15672 (guest/guest)

### Health Checks

- Auth API: http://localhost:8000/health
- Users API: http://localhost:8083/actuator/health
- Todos API: http://localhost:8082/todos

## 🔧 Configuración

### Variables de Entorno

Crea un archivo `.env` basado en `.env.example`:

```bash
cp .env.example .env
# Edita .env según tus necesidades
```

### Personalización de Puertos

Si necesitas cambiar puertos, edita `docker-compose.yml`:

```yaml
services:
  frontend:
    ports:
      - "3001:80"  # Cambiar puerto del frontend
```

## 🐛 Solución de Problemas

### Servicios no inician

```bash
# Verificar estado de Docker
docker info

# Ver logs detallados
./scripts/logs.sh

# Limpiar y reiniciar
./scripts/stop-dev.sh --clean
./scripts/start-dev.sh --build
```

### Puertos en uso

```bash
# Verificar qué proceso usa un puerto
lsof -i :8000

# Detener proceso específico
kill -9 <PID>
```

### Problemas de red

```bash
# Limpiar redes de Docker
docker network prune

# Reiniciar Docker
sudo systemctl restart docker  # Linux
# Restart Docker Desktop       # Windows/Mac
```

### Errores de construcción

```bash
# Limpiar caché de Docker
docker system prune -a

# Reconstruir sin caché
docker-compose build --no-cache
```

## 📊 Monitoreo

### Ver estado de contenedores
```bash
docker-compose ps
```

### Ver uso de recursos
```bash
docker stats
```

### Ver logs en tiempo real
```bash
./scripts/logs.sh -f
```

## 🔄 Desarrollo

### Reiniciar después de cambios de código

```bash
# Para servicios con hot-reload (Node.js, frontend)
./scripts/restart-dev.sh todos-api

# Para servicios compilados (Go, Java)
./scripts/restart-dev.sh auth-api --build
```

### Debugging

```bash
# Acceder a un contenedor
docker exec -it auth-api sh

# Ver logs de base de datos
./scripts/logs.sh users-db

# Conectar a PostgreSQL
docker exec -it users-db psql -U postgres -d usersdb
```

## 🚨 Comandos de Emergencia

```bash
# Detener todo inmediatamente
docker stop $(docker ps -q)

# Limpiar completamente
docker system prune -a --volumes

# Resetear completamente
./scripts/stop-dev.sh --clean
docker volume prune
./scripts/start-dev.sh --build
```

## 📝 Notas Importantes

- Los datos de PostgreSQL se persisten en un volumen Docker
- Redis y RabbitMQ no persisten datos al reiniciar
- Los logs se almacenan en `/logs/` dentro de cada contenedor
- El frontend sirve archivos estáticos desde Nginx
- Las APIs tienen health checks configurados

## 💡 Tips para Desarrollo

1. **Usa health-check.sh regularmente** para verificar el estado
2. **Monitorea logs** con `./scripts/logs.sh -f` durante desarrollo
3. **Reinicia servicios específicos** en lugar de todo el stack
4. **Usa --build** solo cuando cambies Dockerfiles o dependencias
5. **Limpia regularmente** con `docker system prune` para liberar espacio

---

Para más información sobre cada microservicio, consulta su README específico en cada directorio.