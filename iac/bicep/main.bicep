targetScope = 'subscription'

param uniquer string = uniqueString(newGuid())
param location string = deployment().location
param resourcesPrefix string = ''
param apiPoiBaseImageTag string = ''
param apiTripsBaseImageTag string = ''
param apiUserJavaBaseImageTag string = ''
param apiUserprofileBaseImageTag string = ''

var varfile = json(loadTextContent('./variables.json'))
var resourcesPrefixCalculated = empty(resourcesPrefix) ? '${varfile.namePrefix}${uniquer}' : resourcesPrefix
var resourceGroupName = '${resourcesPrefixCalculated}rg'

var apiPoiBaseImageTagCalculated = empty(apiPoiBaseImageTag) ? varfile.baseImageTag : apiPoiBaseImageTag
var apiTripsBaseImageTagCalculated = empty(apiTripsBaseImageTag) ? varfile.baseImageTag : apiTripsBaseImageTag
var apiUserJavaBaseImageTagCalculated = empty(apiUserJavaBaseImageTag) ? varfile.baseImageTag : apiUserJavaBaseImageTag
var apiUserprofileBaseImageTagCalculated = empty(apiUserprofileBaseImageTag) ? varfile.baseImageTag : apiUserprofileBaseImageTag

module openhackResourceGroup './resourceGroup.bicep' = {
  name: '${resourcesPrefixCalculated}-resourceGroupDeployment'
  params: {
    resourceGroupName: resourceGroupName
    location: location
  }
}

module managedIdentity './managedIdentity.bicep' = {
  name: 'managedIdentityDeployment'
  params: {
    resourcesPrefix: resourcesPrefixCalculated
  }
  scope: resourceGroup(resourceGroupName)
  dependsOn: [
    openhackResourceGroup
  ]
}

module containerRegistry './containerRegistry.bicep' = {
  name: 'containerRegistryDeployment'
  params: {
    resourcesPrefix: resourcesPrefixCalculated
  }
  scope: resourceGroup(resourceGroupName)
  dependsOn: [
    openhackResourceGroup
    managedIdentity
  ]
}

module appInsights './appInsights.bicep' = {
  name: 'appInsightsDeployment'
  params: {
    resourcesPrefix: resourcesPrefixCalculated
  }
  scope: resourceGroup(resourceGroupName)
  dependsOn: [
    openhackResourceGroup
  ]
}

module appService './appService.bicep' = {
  name: 'appServiceDeployment'
  params: {
    resourcesPrefix: resourcesPrefixCalculated
    containerRegistryLoginServer: containerRegistry.outputs.containerRegistryLoginServer
    containerRegistryName: containerRegistry.outputs.containerRegistryName
    // userAssignedManagedIdentityId: managedIdentity.outputs.userAssignedManagedIdentityId
    // userAssignedManagedIdentityPrincipalId: managedIdentity.outputs.userAssignedManagedIdentityPrincipalId
    containerRegistryAdminUsername: containerRegistry.outputs.containerRegistryAdminUsername
    containerRegistryAdminPassword: containerRegistry.outputs.containerRegistryAdminPassword
    keyVaultName: keyVault.outputs.name
    appInsightsInstrumentationKey: appInsights.outputs.appInsightsInstrumentationKey
    appInsightsConnectionString: appInsights.outputs.appInsightsConnectionString
    appInsightsStagingInstrumentationKey: appInsights.outputs.appInsightsStagingInstrumentationKey
    appInsightsStagingConnectionString: appInsights.outputs.appInsightsStagingConnectionString
    apiPoiBaseImageTag: apiPoiBaseImageTagCalculated
    apiTripsBaseImageTag: apiTripsBaseImageTagCalculated
    apiUserJavaBaseImageTag: apiUserJavaBaseImageTagCalculated
    apiUserprofileBaseImageTag: apiUserprofileBaseImageTagCalculated
  }
  scope: resourceGroup(resourceGroupName)
  dependsOn: [
    containerRegistry
    apps
    appInsights
  ]
}

module apps './apps.bicep' = {
  name: 'appsDeployment'
  params: {
    resourcesPrefix: resourcesPrefixCalculated
    containerRegistryLoginServer: containerRegistry.outputs.containerRegistryLoginServer
    containerRegistryName: containerRegistry.outputs.containerRegistryName
    userAssignedManagedIdentityId: managedIdentity.outputs.userAssignedManagedIdentityId
    userAssignedManagedIdentityPrincipalId: managedIdentity.outputs.userAssignedManagedIdentityPrincipalId
  }
  scope: resourceGroup(resourceGroupName)
  dependsOn: [
    containerRegistry
    managedIdentity
  ]
}

module logAnalytics './logAnalytics.bicep' = {
  name: 'logAnalyticsDeployment'
  params: {
    resourcesPrefix: resourcesPrefixCalculated
  }
  scope: resourceGroup(resourceGroupName)
  dependsOn: [
    openhackResourceGroup
  ]
}

module containerGroup './containerGroup.bicep' = {
  name: 'containerGroupDeployment'
  params: {
    resourcesPrefix: resourcesPrefixCalculated
    containerRegistryLoginServer: containerRegistry.outputs.containerRegistryLoginServer
    // containerRegistryName: containerRegistry.outputs.containerRegistryName
    containerRegistryAdminUsername: containerRegistry.outputs.containerRegistryAdminUsername
    containerRegistryAdminPassword: containerRegistry.outputs.containerRegistryAdminPassword
    appServiceApiPoiHostname: appService.outputs.appServiceApiPoiHostname
    appServiceApiTripsHostname: appService.outputs.appServiceApiTripsHostname
    appServiceApiUserJavaHostname: appService.outputs.appServiceApiUserJavaHostname
    appServiceApiUserprofileHostname: appService.outputs.appServiceApiUserprofileHostname
    logAnalyticsWorkspaceId: logAnalytics.outputs.logAnalyticsWorkspaceId
    logAnalyticsWorkspaceKey: logAnalytics.outputs.logAnalyticsWorkspaceKey
    // userAssignedManagedIdentityId: managedIdentity.outputs.userAssignedManagedIdentityId
    // userAssignedManagedIdentityPrincipalId: managedIdentity.outputs.userAssignedManagedIdentityPrincipalId
  }
  scope: resourceGroup(resourceGroupName)
  dependsOn: [
    containerRegistry
    appService
    apps
    logAnalytics
  ]
}

module keyVault './keyVault.bicep' = {
  name: 'keyVaultDeployment'
  params: {
    resourcesPrefix: resourcesPrefixCalculated
    containerRegistryAdminPassword: containerRegistry.outputs.containerRegistryAdminPassword
  }
  scope: resourceGroup(resourceGroupName)
  dependsOn: [
    openhackResourceGroup
  ]
}

output appServiceApiPoiHealthcheck string = '${appService.outputs.appServiceApiPoiHostname}/api/healthcheck/poi'
output appServiceApiTripsHealthcheck string = '${appService.outputs.appServiceApiTripsHostname}/api/healthcheck/trips'
output appServiceApiUserJavaHealthcheck string = '${appService.outputs.appServiceApiUserJavaHostname}/api/healthcheck/user-java'
output appServiceApiUserprofileHealthcheck string = '${appService.outputs.appServiceApiUserprofileHostname}/api/healthcheck/user'
