# Usar Java 8 LTS
FROM openjdk:8-jdk-slim

# Establecer directorio de trabajo
WORKDIR /app

# Copiar el JAR real construido por Maven/Gradle
COPY target/users-service.jar users-service.jar

# Exponer puerto 8083
EXPOSE 8083

# Comando para ejecutar
ENTRYPOINT ["java", "-jar", "users-service.jar"]