param resourcesPrefix string
param containerRegistryLoginServer string
param containerRegistryAdminUsername string
@secure()
param containerRegistryAdminPassword string
param appServiceApiPoiHostname string
param appServiceApiTripsHostname string
param appServiceApiUserJavaHostname string
param appServiceApiUserprofileHostname string
param logAnalyticsWorkspaceId string
@secure()
param logAnalyticsWorkspaceKey string
// param containerRegistryName string
// param userAssignedManagedIdentityId string
// param userAssignedManagedIdentityPrincipalId string

// https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles
// AcrPull
// var acrPullRoleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')

// resource containerRegistry 'Microsoft.ContainerRegistry/registries@2021-09-01' existing = {
//   name: containerRegistryName
// }

// https://docs.microsoft.com/en-us/azure/templates/microsoft.authorization/roleassignments?tabs=bicep
// resource acrPullRoleAssignmentSimulator 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = {
//   name: guid(resourceGroup().id, containerRegistry.id, 'simulator', acrPullRoleDefinitionId)
//   scope: containerRegistry
//   properties: {
//     roleDefinitionId: acrPullRoleDefinitionId
//     principalId: userAssignedManagedIdentityPrincipalId
//   }
// }

// https://docs.microsoft.com/en-us/azure/templates/microsoft.containerinstance/containergroups?tabs=bicep
resource containerGroup 'Microsoft.ContainerInstance/containerGroups@2021-09-01' = {
  name: '${resourcesPrefix}simulator'
  location: resourceGroup().location
  // identity: {
  //   type: 'UserAssigned'
  //   userAssignedIdentities: {
  //     '${userAssignedManagedIdentityId}': {}
  //   }
  // }
  properties: {
    containers: [
      {
        name: 'simulator'
        properties: {
          environmentVariables: [
            {
              name: 'TEAM_NAME'
              value: resourcesPrefix
            }
            {
              name: 'USER_ROOT_URL'
              value: 'https://${appServiceApiUserprofileHostname}'
            }
            {
              name: 'USER_JAVA_ROOT_URL'
              value: 'https://${appServiceApiUserJavaHostname}'
            }
            {
              name: 'TRIPS_ROOT_URL'
              value: 'https://${appServiceApiTripsHostname}'
            }
            {
              name: 'POI_ROOT_URL'
              value: 'https://${appServiceApiPoiHostname}'
            }
          ]
          image: '${containerRegistryLoginServer}/devopsoh/simulator:latest'
          ports: [
            {
              port: 8080
              protocol: 'TCP'
            }
          ]
          resources: {
            requests: {
              cpu: 1
              memoryInGB: 2
            }
          }
        }
      }
    ]
    imageRegistryCredentials: [
      {
        password: containerRegistryAdminPassword
        server: containerRegistryLoginServer
        username: containerRegistryAdminUsername
      }
    ]
    ipAddress: {
      dnsNameLabel: '${resourcesPrefix}simulator'
      ports: [
        {
          port: 8080
          protocol: 'TCP'
        }
      ]
      type: 'Public'
    }
    osType: 'Linux'
    diagnostics: {
      logAnalytics: {
        logType: 'ContainerInsights'
        workspaceId: logAnalyticsWorkspaceId
        workspaceKey: logAnalyticsWorkspaceKey
      }
    }
  }
  // dependsOn: [
  //   acrPullRoleAssignmentSimulator
  // ]
}
