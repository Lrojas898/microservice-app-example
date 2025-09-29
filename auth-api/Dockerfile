FROM golang:1.21-alpine AS builder

# Instalar git (requerido para dependencias)
RUN apk add --no-cache git

# Establecer directorio de trabajo
WORKDIR /app

# Copiar go.mod y go.sum primero para mejor caching
COPY go.mod go.sum ./

# Descargar dependencias
RUN go mod download

# Copiar el resto de los archivos Go
COPY . .

# Configurar módulos Go
ENV GO111MODULE=on

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