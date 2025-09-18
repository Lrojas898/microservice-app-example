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

# Create entrypoint script to substitute environment variables
RUN echo '#!/bin/sh' > /docker-entrypoint.sh && \
    echo 'envsubst < /etc/nginx/conf.d/default.conf.template > /etc/nginx/conf.d/default.conf' >> /docker-entrypoint.sh && \
    echo 'exec "$@"' >> /docker-entrypoint.sh && \
    chmod +x /docker-entrypoint.sh

# Exponer puerto 80
EXPOSE 80

# Use custom entrypoint to process environment variables then start nginx
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]