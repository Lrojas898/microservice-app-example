#!/bin/bash
set -e

# Elimina la infraestructura
terraform destroy -auto-approve

echo "Infraestructura eliminada con éxito"