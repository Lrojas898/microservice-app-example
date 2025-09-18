
# Log Processor (Logic App) - CORREGIDO
resource "azurerm_logic_app_workflow" "log_processor" {
  name                = "log-message-processor"
  location            = var.location
  resource_group_name = var.resource_group_name
  workflow_schema     = "https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#"
  workflow_version    = "1.0.0.0"
  depends_on          = [azurerm_resource_group.main]
}
