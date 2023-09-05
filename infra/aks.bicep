param location string = 'eastus'
param aksName string = 'aks-load-testing-demo'
param tags object


resource aksmalt 'Microsoft.LoadTestService/loadTests@2022-12-01' = {
  name: 'aks-malt'
  location: location
  tags: tags
  identity: {
    type: 'None'
  }
}

resource acr 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' = {
  sku: {
    name: 'Standard'
  }
  name: 'aksloadtestdemo'
  location: location
  tags: tags

  properties: {
    adminUserEnabled: true
    dataEndpointEnabled: false
    publicNetworkAccess: 'Enabled'
    networkRuleBypassOptions: 'AzureServices'
    zoneRedundancy: 'Disabled'
    anonymousPullEnabled: false
  }
}

resource aksdemo 'Microsoft.ContainerService/managedClusters@2022-11-02-preview' = {
  location: location
  name: aksName
  tags: tags
  properties: {
    agentPoolProfiles: [
      {
        name: 'nodepool1'
        count: 2
        vmSize: 'Standard_DS2_v2'
        osDiskSizeGB: 128
        osDiskType: 'Managed'
        kubeletDiskType: 'OS'
        maxPods: 110
        type: 'VirtualMachineScaleSets'
        maxCount: 10
        minCount: 1
        enableAutoScaling: true
      }
    ]
  }
  identity: {
    type: 'SystemAssigned'
  }
  sku: {
    name: 'Basic'
    tier: 'Free'
  }
}

var acrPullRole = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')

resource aksAcrPull 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: acr // Use when specifying a scope that is different than the deployment scope
  name: guid(managedCluster.outputs.clusterIdentity.objectId, 'Acr', acrPullRole)
  properties: {
    roleDefinitionId: acrPullRole
    principalType: 'ServicePrincipal'
    principalId: managedCluster.outputs.clusterIdentity.objectId
  }
}
