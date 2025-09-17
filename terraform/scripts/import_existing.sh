#!/usr/bin/env bash
set -euo pipefail

# Importa recursos existentes en Azure al estado de Terraform si ya existen

SUBSCRIPTION_ID=$(az account show --query id -o tsv)
RG_NAME="${1:-microservice-app-rg}"

echo "[import] Subscription: ${SUBSCRIPTION_ID} | Resource Group: ${RG_NAME}"

# Recurso: Resource Group
if az group show -n "${RG_NAME}" >/dev/null 2>&1; then
  echo "[import] Importando Resource Group si no está en estado..."
  terraform state show azurerm_resource_group.main >/dev/null 2>&1 || \
    terraform import azurerm_resource_group.main \
      "/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RG_NAME}"
else
  echo "[import] RG no existe aún, se creará por Terraform"
fi

# Recurso: Application Insights
AI_NAME=${AI_NAME:-microservice-appinsights}
if az resource show -g "${RG_NAME}" -n "${AI_NAME}" --resource-type "Microsoft.Insights/components" >/dev/null 2>&1; then
  echo "[import] Importando Application Insights si no está en estado..."
  terraform state show azurerm_application_insights.main >/dev/null 2>&1 || \
    terraform import azurerm_application_insights.main \
      "/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RG_NAME}/providers/Microsoft.Insights/components/${AI_NAME}"
else
  echo "[import] App Insights no existe, se creará por Terraform"
fi

# Recurso: Logic App Workflow
LA_NAME=${LA_NAME:-log-message-processor}
if az resource show -g "${RG_NAME}" -n "${LA_NAME}" --resource-type "Microsoft.Logic/workflows" >/dev/null 2>&1; then
  echo "[import] Importando Logic App si no está en estado..."
  terraform state show azurerm_logic_app_workflow.log_processor >/dev/null 2>&1 || \
    terraform import azurerm_logic_app_workflow.log_processor \
      "/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RG_NAME}/providers/Microsoft.Logic/workflows/${LA_NAME}"
else
  echo "[import] Logic App no existe, se creará por Terraform"
fi

echo "[import] Finalizado"


