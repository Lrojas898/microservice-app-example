# Build stage: build the JAR with tests skipped
FROM maven:3.8.7-openjdk-8-slim AS build
WORKDIR /build
COPY . .
RUN ./mvnw clean package -DskipTests

# Usar Java 8 LTS
FROM openjdk:8-jdk-slim

# Establecer directorio de trabajo
WORKDIR /app

# Copiar el JAR generado por Maven desde el build stage
COPY --from=build /build/target/*.jar users-service.jar

# Exponer puerto 8083
EXPOSE 8083

# Comando para ejecutar
ENTRYPOINT ["java", "-jar", "users-service.jar"]