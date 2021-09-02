#!/usr/bin/env bash

# ==== Resource Group ====
export SUBSCRIPTION=799c12ba-353c-44a1-883d-84808ebb2216 # customize this
export RESOURCE_GROUP=gzh-pc-local-04-rg # customize this
export LOCATION=SouthCentralUS  #customize this
export COSMOSDB_NAME=gzh-pc-local-04-cosmos  # customize this
export REDIS_NAME=gzh-pc-local-04-redis #customize this
export KEYVAULT_NAME=gzh-pc-local-04-keyvault #customize this
export APP_NAME_FOR_KEYVAULT=local-04-appforkeyvault #customize this

# ==== Create ResouceGroup ====
az group create --name ${RESOURCE_GROUP} \
        --location ${LOCATION}

# ==== Create CosmosDB Account ====
# note： it may take a few minutes
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

SERVICE_PRINCIPAL=$(az ad sp create-for-rbac --name ${APP_NAME_FOR_KEYVAULT} --role Contributor)

AZURE_KEYVAULT_URI=$(az keyvault show --name $KEYVAULT_NAME --resource-group $RESOURCE_GROUP | jq -r .properties | jq -r .vaultUri)
AZURE_KEYVAULT_CLIENTID=$(echo $SERVICE_PRINCIPAL | jq -r .appId)
AZURE_KEYVAULT_TENANTID=$(echo $SERVICE_PRINCIPAL | jq -r .tenant)
AZURE_KEYVAULT_CLIENTKEY=$(echo $SERVICE_PRINCIPAL | jq -r .password)

#
az keyvault set-policy -n $KEYVAULT_NAME --key-permissions get list \
 --certificate-permissions get list \
 --secret-permissions get list \
 --resource-group $RESOURCE_GROUP \
 --spn $AZURE_KEYVAULT_CLIENTID


# ==== add keys to keyvault ====

az keyvault secret set --vault-name $KEYVAULT_NAME --name cosmosdburi --value $COSMOSDB_URI
az keyvault secret set --vault-name $KEYVAULT_NAME --name cosmosdbkey --value $COSMOS_PRIMARY_KEY
az keyvault secret set --vault-name $KEYVAULT_NAME --name cosmosdbsecondarykey --value $COSMOS_SECONDARY_KEY
az keyvault secret set --vault-name $KEYVAULT_NAME --name redisuri --value $REDIS_HOSTNAME
az keyvault secret set --vault-name $KEYVAULT_NAME --name redispassword --value $REDIS_PASSWORD


# ==== Create Kevvault environment file for Docker containers ====
cat > keyvault.env << EOF
AZURE_KEYVAULT_URI=$AZURE_KEYVAULT_URI
AZURE_KEYVAULT_CLIENTID=$AZURE_KEYVAULT_CLIENTID
AZURE_KEYVAULT_TENANTID=$AZURE_KEYVAULT_TENANTID
AZURE_KEYVAULT_CLIENTKEY=$AZURE_KEYVAULT_CLIENTKEY
EOF
