# Build stage: build the JAR with tests skipped
FROM maven:3.8-openjdk-8 AS build
WORKDIR /build
COPY . .
RUN mvn clean package -DskipTests

# Usar Java 8 LTS
FROM openjdk:8-jdk-slim

# Establecer directorio de trabajo
WORKDIR /app

# Copiar el JAR generado por Maven desde el build stage
COPY --from=build /build/target/*.jar users-service.jar

# Exponer puerto 8083
EXPOSE 8083

# Comando para ejecutar con enhanced logging and debugging
ENTRYPOINT ["java", "-Djava.security.egd=file:/dev/./urandom", "-Dspring.profiles.active=docker", "-Dlogging.level.root=INFO", "-Dlogging.level.com.elgris=DEBUG", "-Dlogging.level.org.springframework=INFO", "-Dlogging.level.org.hibernate=INFO", "-jar", "users-service.jar"]