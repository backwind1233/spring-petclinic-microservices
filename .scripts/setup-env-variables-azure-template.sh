#!/usr/bin/env bash

# ==== Resource Group ====
export SUBSCRIPTION=subscription-id # customize this
export RESOURCE_GROUP=resource-group-name # customize this
export LOCATION=SouthCentralUS  #customize this
export COSMOSDB_NAME=mycosmosdbaccname  # customize this
export REDIS_NAME=myredisname #customize this
export KEYVAULT_NAME=myend2endkv #customize this

# ==== Create CosmosDB Account ====
az cosmosdb create --name $COSMOSDB_NAME --resource-group $RESOURCE_GROUP
COSMOS_KEYS=$(az cosmosdb keys list --name $COSMOSDB_NAME --resource-group $RESOURCE_GROUP --type keys)
COSMOS_PRIMARY_KEY=$(echo $COSMOS_KEYS | jq -r .primaryMasterKey)
COSMOS_SECONDARY_KEY=$(echo $COSMOS_KEYS | jq -r .secondaryMasterKey)
COSMOSDB_URI=$(az cosmosdb  show --name $COSMOSDB_NAME --resource-group $RESOURCE_GROUP | jq -r .documentEndpoint)

# ==== Create Redis Cache Account ====
az redis create --name $REDIS_NAME  --resource-group $RESOURCE_GROUP --sku Basic --vm-size c0 --location $LOCATION
REDIS_HOSTNAME=$(az redis show --name $REDIS_NAME --resource-group $RESOURCE_GROUP | jq -r .hostName)
REDIS_PASSWORD=$(az redis list-keys --name $REDIS_NAME --resource-group $RESOURCE_GROUP | jq -r .primaryKey)

# ==== Create a KeyVault Account ====
az keyvault create --location $LOCATION --name $KEYVAULT_NAME --resource-group $RESOURCE_GROUP

SERVICE_PRINCIPAL=$(az ad sp create-for-rbac -n "endtoendsp")
az keyvault set-policy -n MyVault --key-permissions get list --spn $AZURE_KEYVAULT_CLIENTID

AZURE_KEYVAULT_URI=$(az keyvault show --name $KEYVAULT_NAME | jq -r .properties | jq -r .vaultUri)
AZURE_KEYVAULT_CLIENTID=$(echo $SERVICE_PRINCIPAL | jq -r .appId)
AZURE_KEYVAULT_TENANTID=$(echo $SERVICE_PRINCIPAL | jq -r .tenant)
AZURE_KEYVAULT_CLIENTKEY=$(echo $SERVICE_PRINCIPAL | jq -r .password)	


# ==== add keys to keyvault ====
az keyvault secret set --name  cosmosdburi --value  $COSMOSDB_URI
az keyvault secret set --name  cosmosdbkey --value  $COSMOS_PRIMARY_KEY
az keyvault secret set --name  cosmosdbsecondarykey --value  $COSMOS_SECONDARY_KEY
az keyvault secret set --name  redisuri--value  $REDIS_HOSTNAME
az keyvault secret set --name  redispassword --value  $REDIS_PASSWORD

# ==== Create Kevvault environment file for Docker containers ====
cat > keyvault.env << EOF
AZURE_KEYVAULT_URI=$AZURE_KEYVAULT_URI
AZURE_KEYVAULT_CLIENTID=$AZURE_KEYVAULT_CLIENTID
AZURE_KEYVAULT_TENANTID=$AZURE_KEYVAULT_TENANTID
AZURE_KEYVAULT_CLIENTKEY=$AZURE_KEYVAULT_CLIENTKEY
EOF





