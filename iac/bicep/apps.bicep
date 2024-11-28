param resourcesPrefix string
param containerRegistryLoginServer string
param containerRegistryName string
param userAssignedManagedIdentityId string
param userAssignedManagedIdentityPrincipalId string

var location = resourceGroup().location
var varfile = json(loadTextContent('./variables.json'))

// https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles
// Contributor
var contributorRoleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c')

// https://docs.microsoft.com/en-us/azure/templates/microsoft.resources/deploymentscripts?tabs=bicep
resource dataInit 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: '${resourcesPrefix}dataInit'
  location: location
  kind: 'AzureCLI'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userAssignedManagedIdentityId}': {}
    }
  }
  properties: {
    azCliVersion: '2.33.1'
    cleanupPreference: 'Always'
    containerSettings: {
      containerGroupName: '${resourcesPrefix}datainit'
    }
    scriptContent: loadTextContent('datainit.sh')
    environmentVariables: [
      {
        name: 'RESOURCE_GROUP'
        value: resourceGroup().name
      }
      {
        name: 'TEAM_REPO'
        value: varfile.publicTeamRepo
      }
      {
        name: 'TEAM_REPO_BRANCH'
        value: varfile.publicTeamRepoBranch
      }
    ]
    retentionInterval: 'PT1H'
    timeout: 'PT15M'
  }
}

// https://docs.microsoft.com/en-us/azure/templates/microsoft.containerregistry/registries?tabs=bicep
resource containerRegistry 'Microsoft.ContainerRegistry/registries@2021-09-01' existing = {
  name: containerRegistryName
}

// https://docs.microsoft.com/en-us/azure/templates/microsoft.authorization/roleassignments?tabs=bicep
resource acrContributorRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = {
  name: guid(resourceGroup().id, containerRegistry.id, userAssignedManagedIdentityId, contributorRoleDefinitionId)
  scope: containerRegistry
  properties: {
    roleDefinitionId: contributorRoleDefinitionId
    principalId: userAssignedManagedIdentityPrincipalId
  }
}

//https://docs.microsoft.com/en-us/azure/templates/microsoft.resources/deploymentscripts?tabs=bicep
resource dockerBuild 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: '${resourcesPrefix}dockerBuild'
  location: location
  kind: 'AzureCLI'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userAssignedManagedIdentityId}': {}
    }
  }
  properties: {
    azCliVersion: '2.33.1'
    cleanupPreference: 'Always'
    containerSettings: {
      containerGroupName: '${resourcesPrefix}dockerdbuild'
    }
    scriptContent: loadTextContent('dockerbuild.sh')
    environmentVariables: [
      {
        name: 'CONTAINER_REGISTRY'
        value: containerRegistryLoginServer
      }
      {
        name: 'BASE_IMAGE_TAG'
        value: varfile.baseImageTag
      }
      {
        name: 'TEAM_REPO'
        value: varfile.publicTeamRepo
      }
      {
        name: 'TEAM_REPO_BRANCH'
        value: varfile.publicTeamRepoBranch
      }
    ]
    retentionInterval: 'P1D'
  }
  dependsOn: [
    acrContributorRoleAssignment
  ]
}
