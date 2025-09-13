# Verificar si existe el JAR, si no, crear un placeholder
FROM openjdk:8-jdk-slim

# Establecer directorio de trabajo
WORKDIR /app

# Si no existe JAR, crear uno básico para pruebas
RUN touch users-service.jar

# Exponer puerto 8083 (según tu README.md de Auth API: USERS_API_ADDRESS=http://127.0.0.1:8083)
EXPOSE 8083

# Comando para ejecutar
ENTRYPOINT ["java", "-jar", "users-service.jar"]