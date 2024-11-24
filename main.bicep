param location string = 'Italy North'
param aksName string = 'TestAKS'
param vmSize string = 'Standard_B2s'
param nodeCount int = 2

// Add parameters for VM admin credentials
param vmAdminUsername string = 'azureuser'
@secure()
param vmAdminPassword string

// Define the VM size for series D with 2 cores
param vmSize2Cores string = 'Standard_D2s_v3'

// Add parameters for service and pod CIDRs
param serviceCidr string = '10.3.0.0/16'
param dnsServiceIP string = '10.3.0.10'
param podCidr string = '10.2.0.0/16'

// Network Security Group
resource nsg 'Microsoft.Network/networkSecurityGroups@2021-02-01' = {
  name: '${aksName}-nsg'
  location: location
  properties: {
    securityRules: [
      {
        name: 'AllowSSH'
        properties: {
          priority: 1000
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2021-02-01' = {
  name: '${aksName}-vnet'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'subnet1'
        properties: {
          addressPrefix: '10.0.1.0/24'
          networkSecurityGroup: {
            id: nsg.id
          }
        }
      }
      {
        name: 'subnet2'
        properties: {
          addressPrefix: '10.0.2.0/24'
          networkSecurityGroup: {
            id: nsg.id
          }
        }
      }
    ]
  }
}

resource aksCluster 'Microsoft.ContainerService/managedClusters@2024-08-01' = {
  name: aksName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    kubernetesVersion: '1.28.9'
    dnsPrefix: aksName

    agentPoolProfiles: [
      {
        name: 'agentpool'
        count: nodeCount
        vmSize: vmSize
        osType: 'Linux'
        vnetSubnetID: vnet.properties.subnets[0].id
        mode: 'System' // Add this line
      }
    ]
    networkProfile: {
      networkPlugin: 'azure'
      loadBalancerSku: 'Standard'
      networkPolicy: 'calico'
      serviceCidr: serviceCidr
      dnsServiceIP: dnsServiceIP
      podCidr: podCidr
     
    }
    // Attach ACR to AKS
    addonProfiles: {
      azureKeyvaultSecretsProvider: {
        enabled: true
        config: {
          secretStore: 'AzureKeyVault'
        }
      }
     
    }
  }
}

// Public IP for VM1
resource publicIP1 'Microsoft.Network/publicIPAddresses@2021-02-01' = {
  name: 'publicIP1'
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
}

// Network Interface for VM1
resource nic1 'Microsoft.Network/networkInterfaces@2021-02-01' = {
  name: 'nic1'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: vnet.properties.subnets[0].id
          }
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIP1.id
          }
        }
      }
    ]
  }
}

// Virtual Machine VM1 in subnet1
resource vm1 'Microsoft.Compute/virtualMachines@2021-07-01' = {
  name: 'vm1'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize2Cores
    }
    osProfile: {
      computerName: 'vm1'
      adminUsername: vmAdminUsername
      adminPassword: vmAdminPassword
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic1.id
        }
      ]
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2019-Datacenter'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
      }
    }
  }
}

resource vm1CustomScript 'Microsoft.Compute/virtualMachines/extensions@2021-07-01' = {
  parent: vm1
  name: 'installTelnet'
  location: location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: []
      commandToExecute: 'powershell.exe Install-WindowsFeature -Name Telnet-Client'
    }
  }
}

// Public IP for VM2
resource publicIP2 'Microsoft.Network/publicIPAddresses@2021-02-01' = {
  name: 'publicIP2'
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
}

// Network Interface for VM2
resource nic2 'Microsoft.Network/networkInterfaces@2021-02-01' = {
  name: 'nic2'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: vnet.properties.subnets[1].id
          }
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIP2.id
          }
        }
      }
    ]
  }
}

// Virtual Machine VM2 in subnet2
resource vm2 'Microsoft.Compute/virtualMachines@2021-07-01' = {
  name: 'vm2'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize2Cores
    }
    osProfile: {
      computerName: 'vm2'
      adminUsername: vmAdminUsername
      adminPassword: vmAdminPassword
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic2.id
        }
      ]
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2019-Datacenter'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
      }
    }
  }
}

resource vm2CustomScript 'Microsoft.Compute/virtualMachines/extensions@2021-07-01' = {
  parent: vm2
  name: 'installTelnet'
  location: location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: []
      commandToExecute: 'powershell.exe Install-WindowsFeature -Name Telnet-Client'
    }
  }
}

resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: 'testgabacr' // Updated name to meet naming requirements
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: true
  }
}

resource acrRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(subscription().subscriptionId, acr.id, 'acrpull')
  scope: acr
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d') // AcrPull role
    principalId: aksCluster.properties.identityProfile.kubeletidentity.objectId
    principalType: 'ServicePrincipal'
  }
}
