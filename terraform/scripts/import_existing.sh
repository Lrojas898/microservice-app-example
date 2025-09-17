#!/usr/bin/env bash
# Script: import_existing.sh
# Descripción: Importa recursos existentes en Azure al estado de Terraform si ya existen,
#              o alerta si hay recursos que requieren atención especial (como purga).
# Uso: ./import_existing.sh <nombre_grupo_de_recursos>
# Ejemplo: ./import_existing.sh microservice-app-rg

set -euo pipefail # Salir inmediatamente si un comando falla (-e), si se usan variables no definidas (-u),
                  # y el estado de retorno de un pipeline es el del último comando (-o pipefail).

# === CONFIGURACIÓN INICIAL ===
# Obtiene el ID de la suscripción actual de Azure CLI.
SUBSCRIPTION_ID=$(az account show --query id -o tsv)

# Obtiene el nombre del grupo de recursos del primer argumento del script, o usa 'microservice-app-rg' por defecto.
RG_NAME="${1:-microservice-app-rg}"

# Obtiene el nombre del Key Vault de una variable de entorno o usa 'microservice-kv' por defecto.
# Asegúrate de que este nombre coincida con el definido en tus variables de Terraform (var.key_vault_name).
KV_NAME=${KV_NAME:-microservice-kv}

# Imprime información de contexto para el registro.
echo "[import] Subscription: ${SUBSCRIPTION_ID} | Resource Group: ${RG_NAME} | Key Vault: ${KV_NAME}"
# =============================

# === IMPORTACIÓN DE RECURSOS EXISTENTES ===

# --- Recurso: Resource Group ---
# Verifica si el grupo de recursos ya existe en Azure.
if az group show -n "${RG_NAME}" >/dev/null 2>&1; then
  echo "[import] El Resource Group ya existe. Importando al estado de Terraform si no está presente..."
  # Verifica si el estado de Terraform ya lo conoce.
  terraform state show azurerm_resource_group.main >/dev/null 2>&1 || \
    # Si no está en el estado, lo importa.
    terraform import azurerm_resource_group.main \
      "/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RG_NAME}"
else
  echo "[import] El Resource Group '${RG_NAME}' no existe aún. Terraform lo creará."
fi
# -----------------------------

# --- Recurso: Application Insights ---
# Define el nombre esperado del recurso Application Insights.
AI_NAME=${AI_NAME:-microservice-appinsights}
# Verifica si el recurso ya existe en el grupo de recursos especificado.
if az resource show -g "${RG_NAME}" -n "${AI_NAME}" --resource-type "Microsoft.Insights/components" >/dev/null 2>&1; then
  echo "[import] Application Insights '${AI_NAME}' ya existe. Importando al estado de Terraform si no está presente..."
  # Verifica si el estado de Terraform ya lo conoce.
  terraform state show azurerm_application_insights.main >/dev/null 2>&1 || \
    # Si no está en el estado, lo importa.
    terraform import azurerm_application_insights.main \
      "/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RG_NAME}/providers/Microsoft.Insights/components/${AI_NAME}"
else
  echo "[import] Application Insights '${AI_NAME}' no existe. Terraform lo creará."
fi
# ---------------------------------

# --- Recurso: Logic App Workflow ---
# Define el nombre esperado del recurso Logic App.
LA_NAME=${LA_NAME:-log-message-processor}
# Verifica si el recurso ya existe en el grupo de recursos especificado.
if az resource show -g "${RG_NAME}" -n "${LA_NAME}" --resource-type "Microsoft.Logic/workflows" >/dev/null 2>&1; then
  echo "[import] Logic App Workflow '${LA_NAME}' ya existe. Importando al estado de Terraform si no está presente..."
  # Verifica si el estado de Terraform ya lo conoce.
  terraform state show azurerm_logic_app_workflow.log_processor >/dev/null 2>&1 || \
    # Si no está en el estado, lo importa.
    terraform import azurerm_logic_app_workflow.log_processor \
      "/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RG_NAME}/providers/Microsoft.Logic/workflows/${LA_NAME}"
else
  echo "[import] Logic App Workflow '${LA_NAME}' no existe. Terraform lo creará."
fi
# ---------------------------------

# --- Recurso: Key Vault (MANEJO ESPECIAL PARA SOFT-DELETE) ---
echo "[import] Verificando estado del Key Vault: ${KV_NAME}"

# Verificar si el Key Vault existe en estado ACTIVO.
if az keyvault show --name "${KV_NAME}" >/dev/null 2>&1; then
    echo "[import] Key Vault '${KV_NAME}' existe en estado ACTIVO."
    echo "[import] Importando Key Vault al estado de Terraform si no está presente..."
    # Verifica si el estado de Terraform ya lo conoce.
    terraform state show azurerm_key_vault.main >/dev/null 2>&1 || \
      # Si no está en el estado, lo importa.
      terraform import azurerm_key_vault.main \
        "/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RG_NAME}/providers/Microsoft.KeyVault/vaults/${KV_NAME}"

# Verificar si el Key Vault existe en estado ELIMINADO (soft-delete).
elif az keyvault show-deleted --name "${KV_NAME}" >/dev/null 2>&1; then
    echo "[import] ADVERTENCIA CRÍTICA: Key Vault '${KV_NAME}' existe en estado ELIMINADO (soft-delete)."
    echo "[import] Terraform NO PUEDE crear un Key Vault con el mismo nombre hasta que el existente sea PURGADO."
    echo "[import] Acción requerida: El Key Vault debe ser purgado manualmente o automáticamente (requiere permisos)."
    echo "[import] Comando para purga manual (ejecutar con CLI de Azure y permisos adecuados):"
    echo "[import]   az keyvault purge --name ${KV_NAME} --location <tu-region-de-azure>"
    
    # === OPCIÓN PARA PURGA AUTOMÁTICA (COMENTADA POR SEGURIDAD) ===
    # Descomentar las siguientes líneas SOLO si estás SEGURO de que la identidad que ejecuta
    # este script (por ejemplo, la Service Principal de la pipeline) tiene el permiso especial
    # 'Microsoft.KeyVault/locations/deletedVaults/purge/action'.
    # La purga automática puede tener consecuencias si no se maneja con cuidado.
    # ---------------------------------------------------------------
    # echo "[import] Intentando purga automática (puede fallar por permisos)..."
    # if az keyvault purge --name "${KV_NAME}" --yes; then
    #     echo "[import] Key Vault '${KV_NAME}' ha sido PURGADO exitosamente."
    #     echo "[import] Terraform procederá a crear uno nuevo con el mismo nombre."
    # else
    #     echo "[import] ERROR: No se pudo purgar el Key Vault '${KV_NAME}'."
    #     echo "[import] Verifica los permisos de la identidad que ejecuta este script."
    #     echo "[import] La ejecución de Terraform probablemente fallará. Se requiere intervención manual."
    #     # Salir con error para detener la pipeline y alertar.
    #     # exit 1
    # fi
    # ---------------------------------------------------------------
    
    # Si no se purga automáticamente o se deja comentado, se advierte y se permite continuar.
    # Terraform fallará en el siguiente paso al intentar crear el KV, lo cual es esperado.
    echo "[import] Continuando la ejecución. Terraform fallará al crear el Key Vault si no se purga."

else
    # Si no existe en ningún estado, Terraform lo creará.
    echo "[import] Key Vault '${KV_NAME}' no existe (ni activo ni eliminado). Terraform lo creará."
fi
# ---------------------------------------------------------------
# ==========================================

# Mensaje de finalización del script.
echo "[import] Finalizado el proceso de verificación e importación de recursos existentes."