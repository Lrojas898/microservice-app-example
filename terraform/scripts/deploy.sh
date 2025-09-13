#!/bin/bash
set -e

terraform init

terraform validate

terraform plan -out=tfplan


terraform apply tfplan

echo "Infraestructura desplegada con éxito"