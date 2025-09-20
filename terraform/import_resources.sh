#!/bin/bash

# Script to import existing Azure resources into Terraform state
# Run this script from the terraform directory

echo "Starting import of existing Azure resources..."

# Set the resource group name
RG_NAME="microservice-app-rg"

# Get subscription ID
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
echo "Using subscription: $SUBSCRIPTION_ID"

# Import Container Groups
echo "Importing container groups..."
terraform import azurerm_container_group.auth "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RG_NAME/providers/Microsoft.ContainerInstance/containerGroups/auth-service"
terraform import azurerm_container_group.users "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RG_NAME/providers/Microsoft.ContainerInstance/containerGroups/users-service"
terraform import azurerm_container_group.todos "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RG_NAME/providers/Microsoft.ContainerInstance/containerGroups/todos-service"

# Get the object ID for the current user (for Key Vault access policy)
CURRENT_USER_OBJECT_ID=$(az ad signed-in-user show --query id -o tsv)
echo "Current user object ID: $CURRENT_USER_OBJECT_ID"

# Import Key Vault access policy
echo "Importing Key Vault access policy..."
terraform import azurerm_key_vault_access_policy.current "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RG_NAME/providers/Microsoft.KeyVault/vaults/microservice-kv/objectId/$CURRENT_USER_OBJECT_ID"

# Import Private Endpoint and DNS Zone
echo "Importing private endpoint and DNS zone..."
terraform import module.security.azurerm_private_endpoint.redis "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RG_NAME/providers/Microsoft.Network/privateEndpoints/redis-pe"
terraform import module.security.azurerm_private_dns_zone.redis "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RG_NAME/providers/Microsoft.Network/privateDnsZones/privatelink.redis.cache.windows.net"

echo "Import completed! You can now run 'terraform plan' to see what changes are needed."