# Stage 1: Build
FROM node:16-alpine AS builder

# Establecer directorio de trabajo
WORKDIR /app

# Copiar package.json primero para mejor cache
COPY package*.json ./

# Install dependencies faster
RUN npm install --legacy-peer-deps --silent

# Copiar solo los archivos necesarios
COPY src/ ./src/
COPY build/ ./build/
COPY config/ ./config/
COPY static/ ./static/
COPY index.html ./
COPY .eslintrc.js ./
COPY .babelrc ./
COPY .postcssrc.js ./

# Construir la aplicación
RUN npm run build

# Stage 2: Serve
FROM nginx:alpine

# Install envsubst (gettext package) for environment variable substitution
RUN apk add --no-cache gettext

# Copiar archivos construidos
COPY --from=builder /app/dist /usr/share/nginx/html

# Copiar configuración de nginx como template
COPY nginx.conf /etc/nginx/conf.d/default.conf.template

# Create enhanced entrypoint script with comprehensive logging
RUN echo '#!/bin/sh' > /docker-entrypoint.sh && \
    echo 'set -e' >> /docker-entrypoint.sh && \
    echo 'echo "=== Frontend Container Startup Debug ==="' >> /docker-entrypoint.sh && \
    echo 'echo "Date: $(date)"' >> /docker-entrypoint.sh && \
    echo 'echo "Working directory: $(pwd)"' >> /docker-entrypoint.sh && \
    echo 'echo "User: $(whoami)"' >> /docker-entrypoint.sh && \
    echo 'echo "Available memory: $(free -h)"' >> /docker-entrypoint.sh && \
    echo 'echo ""' >> /docker-entrypoint.sh && \
    echo 'echo "=== Environment Variables ==="' >> /docker-entrypoint.sh && \
    echo 'echo "AUTH_API_ADDRESS: ${AUTH_API_ADDRESS:-NOT_SET}"' >> /docker-entrypoint.sh && \
    echo 'echo "TODOS_API_ADDRESS: ${TODOS_API_ADDRESS:-NOT_SET}"' >> /docker-entrypoint.sh && \
    echo 'echo ""' >> /docker-entrypoint.sh && \
    echo 'echo "=== Testing Backend Connectivity ==="' >> /docker-entrypoint.sh && \
    echo 'if [ -n "$AUTH_API_ADDRESS" ]; then' >> /docker-entrypoint.sh && \
    echo '  echo "Testing auth API: $AUTH_API_ADDRESS"' >> /docker-entrypoint.sh && \
    echo '  wget -q --timeout=5 --tries=1 "$AUTH_API_ADDRESS" -O- 2>/dev/null && echo "Auth API: OK" || echo "Auth API: FAIL - trying /health"' >> /docker-entrypoint.sh && \
    echo '  wget -q --timeout=5 --tries=1 "$AUTH_API_ADDRESS/health" -O- 2>/dev/null && echo "Auth API /health: OK" || echo "Auth API /health: FAIL"' >> /docker-entrypoint.sh && \
    echo 'fi' >> /docker-entrypoint.sh && \
    echo 'if [ -n "$TODOS_API_ADDRESS" ]; then' >> /docker-entrypoint.sh && \
    echo '  echo "Testing todos API: $TODOS_API_ADDRESS"' >> /docker-entrypoint.sh && \
    echo '  wget -q --timeout=5 --tries=1 "$TODOS_API_ADDRESS" -O- 2>/dev/null && echo "Todos API: OK" || echo "Todos API: FAIL - trying /todos"' >> /docker-entrypoint.sh && \
    echo '  wget -q --timeout=5 --tries=1 "$TODOS_API_ADDRESS/todos" -O- 2>/dev/null && echo "Todos API /todos: OK" || echo "Todos API /todos: FAIL"' >> /docker-entrypoint.sh && \
    echo 'fi' >> /docker-entrypoint.sh && \
    echo 'echo ""' >> /docker-entrypoint.sh && \
    echo 'echo "=== File System Check ==="' >> /docker-entrypoint.sh && \
    echo 'echo "Nginx template exists: $(test -f /etc/nginx/conf.d/default.conf.template && echo YES || echo NO)"' >> /docker-entrypoint.sh && \
    echo 'echo "HTML files exist: $(test -d /usr/share/nginx/html && echo YES || echo NO)"' >> /docker-entrypoint.sh && \
    echo 'echo "HTML file count: $(ls -la /usr/share/nginx/html | wc -l)"' >> /docker-entrypoint.sh && \
    echo 'echo ""' >> /docker-entrypoint.sh && \
    echo 'echo "=== Processing Nginx Configuration ==="' >> /docker-entrypoint.sh && \
    echo 'echo "Before envsubst - template content:"' >> /docker-entrypoint.sh && \
    echo 'head -20 /etc/nginx/conf.d/default.conf.template' >> /docker-entrypoint.sh && \
    echo 'echo ""' >> /docker-entrypoint.sh && \
    echo 'echo "Running envsubst..."' >> /docker-entrypoint.sh && \
    echo 'if envsubst '\''$AUTH_API_ADDRESS $TODOS_API_ADDRESS'\'' < /etc/nginx/conf.d/default.conf.template > /etc/nginx/conf.d/default.conf; then' >> /docker-entrypoint.sh && \
    echo '  echo "envsubst: SUCCESS"' >> /docker-entrypoint.sh && \
    echo 'else' >> /docker-entrypoint.sh && \
    echo '  echo "envsubst: FAILED with exit code $?"' >> /docker-entrypoint.sh && \
    echo '  exit 1' >> /docker-entrypoint.sh && \
    echo 'fi' >> /docker-entrypoint.sh && \
    echo 'echo ""' >> /docker-entrypoint.sh && \
    echo 'echo "After envsubst - nginx config:"' >> /docker-entrypoint.sh && \
    echo 'head -30 /etc/nginx/conf.d/default.conf' >> /docker-entrypoint.sh && \
    echo 'echo ""' >> /docker-entrypoint.sh && \
    echo 'echo "=== Testing Nginx Configuration ==="' >> /docker-entrypoint.sh && \
    echo 'if nginx -t 2>&1; then' >> /docker-entrypoint.sh && \
    echo '  echo "Nginx config test: PASSED"' >> /docker-entrypoint.sh && \
    echo 'else' >> /docker-entrypoint.sh && \
    echo '  echo "Nginx config test: FAILED"' >> /docker-entrypoint.sh && \
    echo '  echo "Nginx config errors above"' >> /docker-entrypoint.sh && \
    echo '  exit 1' >> /docker-entrypoint.sh && \
    echo 'fi' >> /docker-entrypoint.sh && \
    echo 'echo ""' >> /docker-entrypoint.sh && \
    echo 'echo "=== Starting Nginx ==="' >> /docker-entrypoint.sh && \
    echo 'echo "About to start: $@"' >> /docker-entrypoint.sh && \
    echo 'echo "Starting nginx in foreground..."' >> /docker-entrypoint.sh && \
    echo 'exec "$@"' >> /docker-entrypoint.sh && \
    chmod +x /docker-entrypoint.sh

# Exponer puerto 80
EXPOSE 80

# Use custom entrypoint to process environment variables then start nginx
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]