param location string = resourceGroup().location
param first_container_name string = 'first-container'
param second_container_name string = 'second-container'
param loadBalancer_name string = 'iac-lb'
param publicIPAddresses_name string = 'iac-ip' 
param virtualNetwork_name string = 'iac-vnet'
param image_name string  = 'sanoopsadique/iac:latest'
param address_space string  = '10.0.0.0/16'
param subnet string  = '10.0.0.0/24'

var interfaceConfigName = 'eth0'

resource virtualNetwork_name_resource 'Microsoft.Network/virtualNetworks@2022-01-01' = {
  location: location
  name: virtualNetwork_name
  properties: {
    addressSpace: {
      addressPrefixes: [
        address_space
      ]
    }
    enableDdosProtection: false
    subnets: [
      {
        name: 'default'
        properties: {
          addressPrefix: subnet
          delegations: [
            {
              name: 'ACIDelegationService'
              properties: {
                serviceName: 'Microsoft.ContainerInstance/containerGroups'
              }
              type: 'Microsoft.Network/virtualNetworks/subnets/delegations'
            }
          ]
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
        type: 'Microsoft.Network/virtualNetworks/subnets'
      }
    ]
    virtualNetworkPeerings: []
  }
}

resource virtualNetwork_subnet_default 'Microsoft.Network/virtualNetworks/subnets@2022-01-01' = {
  name: '${virtualNetwork_name}/default'
  properties: {
    addressPrefix: subnet
    delegations: [
      {
        name: 'ACIDelegationService'
        properties: {
          serviceName: 'Microsoft.ContainerInstance/containerGroups'
        }
        type: 'Microsoft.Network/virtualNetworks/subnets/delegations'
      }
    ]
    privateEndpointNetworkPolicies: 'Disabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
  }
  dependsOn: [
    virtualNetwork_name_resource
  ]
}

resource networkProfile 'Microsoft.Network/networkProfiles@2020-11-01' = {
  name: 'aci-networkProfile'
  location: location
  properties: {
    containerNetworkInterfaceConfigurations: [
      {
        name: interfaceConfigName
        properties: {
          ipConfigurations: [
            {
              name: 'ipconfigprofile1'
              properties: {
                subnet: {
                  id: virtualNetwork_subnet_default.id
                }
              }
            }
          ]
        }
      }
    ]
  }
}

resource first_container_name_resource 'Microsoft.ContainerInstance/containerGroups@2019-12-01' = {
  location: location
  name: first_container_name
  properties: {
    containers: [
      {
        name: first_container_name
        properties: {
          environmentVariables: []
          image: image_name
          ports: [
            {
              port: 80
              protocol: 'TCP'
            }
          ]
          resources: {
            requests: {
              cpu: 1
              memoryInGB: 1
            }
          }
        }
      }
    ]
    networkProfile: {
      id: networkProfile.id
    }
    osType: 'Linux'
    restartPolicy: 'OnFailure'
    sku: 'Standard'
    
  }
}

resource second_container_name_resource 'Microsoft.ContainerInstance/containerGroups@2019-12-01' = {
  location: location
  name: second_container_name
  properties: {
    containers: [
      {
        name: second_container_name
        properties: {
          environmentVariables: []
          image: image_name
          ports: [
            {
              port: 80
              protocol: 'TCP'
            }
          ]
          resources: {
            requests: {
              cpu: 1
              memoryInGB: 1
            }
          }
        }
      }
    ]
    initContainers: []
    networkProfile: {
      id: networkProfile.id
    }
    osType: 'Linux'
    restartPolicy: 'OnFailure'
    sku: 'Standard'
    
  }
}
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


resource loadBalancer_name_resource 'Microsoft.Network/loadBalancers@2022-01-01' = {
  location: location
  name: loadBalancer_name
  properties: {
    backendAddressPools: [
      {
        name: 'container-backend'
        properties: {
          loadBalancerBackendAddresses: [
            {
              name: 'first-backend'
              properties: {
                ipAddress: first_container_name_resource.properties.ipAddress.ip
                loadBalancerFrontendIPConfiguration: {
                  id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', loadBalancer_name, 'loadBalancer-frontend')
                }
                subnet: {
                  id: virtualNetwork_subnet_default.id
                }
                virtualNetwork: {
                  id: virtualNetwork_name_resource.id
                }
              }
            }
            {
              name: 'second-backend'
              properties: {
                ipAddress: second_container_name_resource.properties.ipAddress.ip
                subnet: {
                  id: virtualNetwork_subnet_default.id
                }
                virtualNetwork: {
                  id: virtualNetwork_name_resource.id
                }
              }
            }
          ]
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'loadBalancer-frontend'
        properties: {
          publicIPAddress: {
            id: publicIPAddresses_name_resource.id
          }
        }
      }
    ]
    probes: [
      {
        name: 'loadBalancer-HealthProbe'
        properties: {
          intervalInSeconds: 5
          numberOfProbes: 1
          port: 80
          protocol: 'Http'
          requestPath: '/'
        }
      }
    ]
    loadBalancingRules: [
      {
        name: 'loadBalancer-rule'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', loadBalancer_name, 'loadBalancer-frontend')
          }
          backendAddressPools: [
            {
              id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', loadBalancer_name, 'container-backend')
            }
          ]
          backendPort: 80
          
          frontendPort: 80
          idleTimeoutInMinutes: 4
          loadDistribution: 'Default'
          probe: {
            id: resourceId('Microsoft.Network/loadBalancers/probes', loadBalancer_name, 'loadBalancer-HealthProbe')
          }
          protocol: 'Tcp'
        }
      }
    ]
    
    
  }
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
}
