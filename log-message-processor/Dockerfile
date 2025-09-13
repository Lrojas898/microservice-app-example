# Usar Python 3.7 (versión común para este tipo de procesadores)
FROM python:3.7-slim

# Establecer directorio de trabajo
WORKDIR /app

# Instalar redis (requerido para consumir mensajes de Redis)
RUN pip install redis

# Copiar el resto de la aplicación
COPY . .

# Comando para iniciar el procesador
CMD ["python", "main.py"]