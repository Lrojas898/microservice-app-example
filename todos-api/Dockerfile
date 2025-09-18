# Usar Node.js 14 LTS
FROM node:14.21.3-alpine

# Establecer directorio de trabajo
WORKDIR /app

# Copiar package.json y package-lock.json
COPY package*.json ./

# Instalar dependencias
RUN npm install

# Copiar el resto de la aplicación
COPY . .

# Exponer puerto 8082 (según tu README.md: TODO_API_PORT=8082)
EXPOSE 8082

# Comando para iniciar la aplicación
CMD ["npm", "start"]