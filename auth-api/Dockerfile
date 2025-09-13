FROM golang:1.18-alpine AS builder

# Instalar git (requerido para dependencias)
RUN apk add --no-cache git

# Establecer directorio de trabajo
WORKDIR /app

# Copiar archivos Go
COPY . .

# Configurar módulos Go (basado en tu README.md)
ENV GO111MODULE=on
RUN go mod init github.com/bortizf/microservice-app-example/auth-api
RUN go mod tidy

# Construir el binario
RUN CGO_ENABLED=0 GOOS=linux go build -o auth-service .

# Imagen final
FROM alpine:latest
RUN apk --no-cache add ca-certificates
WORKDIR /root/

# Copiar binario desde el stage de build
COPY --from=builder /app/auth-service .

# Exponer puerto 8000 (según tu README.md)
EXPOSE 8000

# Comando para ejecutar (según tu README.md)
CMD ["./auth-service"]