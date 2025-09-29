# Build stage
FROM maven:3.8.4-openjdk-8-slim AS build
WORKDIR /app
COPY pom.xml .
RUN mvn dependency:go-offline -B
COPY src ./src
RUN mvn clean package -DskipTests

# Runtime stage
FROM openjdk:8-jre-slim
WORKDIR /app

# Install curl for health checks
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

# Copy the jar file
COPY --from=build /app/target/*.jar app.jar

# Create non-root user
RUN groupadd -r appuser && useradd -r -g appuser appuser
RUN chown appuser:appuser app.jar
USER appuser

# Health check - use actuator health endpoint (permitted in security config)
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD curl -f http://localhost:8083/actuator/health || exit 1

# Enhanced JVM settings for Java 8 and containers
ENTRYPOINT ["java", \
    "-Djava.security.egd=file:/dev/./urandom", \
    "-Dspring.profiles.active=docker", \
    "-Xms256m", \
    "-Xmx512m", \
    "-XX:+UseG1GC", \
    "-XX:MaxGCPauseMillis=200", \
    "-XX:+UnlockExperimentalVMOptions", \
    "-XX:+UseCGroupMemoryLimitForHeap", \
    "-XX:+HeapDumpOnOutOfMemoryError", \
    "-XX:HeapDumpPath=/tmp/heapdump.hprof", \
    "-Dlogging.level.org.springframework.boot.autoconfigure=INFO", \
    "-Dlogging.level.org.springframework.jdbc.core=INFO", \
    "-Dspring.datasource.url=jdbc:h2:mem:usersdb;DB_CLOSE_DELAY=-1;DB_CLOSE_ON_EXIT=FALSE", \
    "-Dspring.datasource.driver-class-name=org.h2.Driver", \
    "-Dspring.jpa.database-platform=org.hibernate.dialect.H2Dialect", \
    "-jar", "app.jar"]