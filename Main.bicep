// Parameters
@description('Environment prefix for resource naming')
@allowed([
  'dev'
  'test'
  'prod'
])
param environment string = 'prod'

@description('Azure region for resources')
param location string = 'uksouth'

@description('Virtual network address space')
param vnetAddressPrefix string = '10.150.0.0/22'

@description('Tags to apply to all resources')
param tags object = {
  Environment: environment
  ManagedBy: 'Bicep'
  Project: 'swoo'
}

// Variables
var prefix = environment
var vnetName = '${prefix}swoo-vnet-${location}'
var nsgName = '${prefix}swoo-nsg-${location}'
var logAnalyticsWorkspaceName = '${prefix}swoo-law-${location}'

// Log Analytics Workspace for monitoring
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: logAnalyticsWorkspaceName
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
  }
}

// Network Security Group
resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2023-06-01' = {
  name: nsgName
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'AllowHTTPS'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'AllowRDP'
        properties: {
          priority: 110
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3389'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

// Virtual Network
resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-06-01' = {
  name: vnetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: 'GatewaySubnet'
        properties: {
          addressPrefix: '10.150.3.240/28'
        }
      }
      {
        name: 'swoo-sub-ds-uks'
        properties: {
          addressPrefix: '10.150.3.192/28'
          networkSecurityGroup: {
            id: networkSecurityGroup.id
          }
        }
      }
      {
        name: 'swoo-sub-avd-uks'
        properties: {
          addressPrefix: '10.150.3.96/27'
          networkSecurityGroup: {
            id: networkSecurityGroup.id
          }
        }
      }
      {
        name: 'swoo-sub-sql-uks'
        properties: {
          addressPrefix: '10.150.2.64/26'
          networkSecurityGroup: {
            id: networkSecurityGroup.id
          }
        }
      }
    ]
    enableDdosProtection: false
  }
}

// Outputs
output vnetId string = virtualNetwork.id
output vnetName string = virtualNetwork.name
output logAnalyticsWorkspaceId string = logAnalyticsWorkspace.id
output nsgId string = networkSecurityGroup.id
