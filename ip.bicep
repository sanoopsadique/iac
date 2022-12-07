param location string = resourceGroup().location
param publicIPAddresses_name string = 'iac-ip' 


resource publicIPAddresses_name_resource 'Microsoft.Network/publicIPAddresses@2022-01-01' = {
  location: location
  name: publicIPAddresses_name
  properties: {
    idleTimeoutInMinutes: 4
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
  }
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  zones: [
    '2'
    '3'
    '1'
  ]
}
