// Key Vault bootstap for further challenges - not used in the beginning.
param resourcesPrefix string
param location string = resourceGroup().location
param containerRegistryAdminPassword string

// https://docs.microsoft.com/en-us/azure/templates/microsoft.keyvault/vaults?tabs=bicep
resource keyVault 'Microsoft.KeyVault/vaults@2021-06-01-preview' = {
  name: '${resourcesPrefix}kv'
  location: location
  
  properties: {
    sku: {
      name: 'standard'
      family: 'A'
    }
    tenantId: subscription().tenantId

    accessPolicies: []
    softDeleteRetentionInDays: 7
  }
}

resource dockerRegistryServerPassword 'Microsoft.KeyVault/vaults/secrets@2021-06-01-preview' = {
  parent: keyVault
  name: 'DOCKER-REGISTRY-SERVER-PASSWORD'
  
  properties: {
    value: containerRegistryAdminPassword
  }
}

output name string = keyVault.name
