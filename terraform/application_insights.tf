# Application Insights para monitoreo
resource "azurerm_application_insights" "main" {
  name                = "microservice-appinsights"
  location            = var.location
  resource_group_name = var.resource_group_name
  application_type    = "web"
}

# Log Processor
resource "azurerm_logic_app_workflow" "log_processor" {
  name                = "log-message-processor"
  location            = var.location
  resource_group_name = var.resource_group_name

  definition = <<DEFINITION
{
  "$schema": "https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#",
  "actions": {
    "HTTP": {
      "inputs": {
        "body": "@triggerBody()",
        "method": "POST",
        "uri": "${azurerm_application_insights.main.instrumentation_key}"
      },
      "runAfter": {},
      "type": "Http"
    }
  },
  "contentVersion": "1.0.0.0",
  "outputs": {},
  "parameters": {},
  "triggers": {
    "manual": {
      "inputs": {
        "schema": {}
      },
      "kind": "Http",
      "type": "Request"
    }
  }
}
DEFINITION
}