var prefix = 'prod'
var vnetname = '${prefix}swoo-vnet-uks'
var location = 'uksouth'

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-06-01' = {
  name: vnetname
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.150.0.0/22'
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
        }
      }
      {
        name: 'swoo-sub-avd-uks'
        properties: {
          addressPrefix: '10.150.3.96/27'
        }
      }
      {
        name: 'swoo-sub-sql-uks'
        properties: {
          addressPrefix: '10.150.2.64/26'
        }
      }
    ]
  }
}
