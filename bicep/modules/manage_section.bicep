//*****************************************************************//
//  Manage Section                                                 //
//*****************************************************************//

type manageSettings = {
  @description('The name of the section name')
  sectionName: string
  @description('The display name of the section')
  displayName: string
  @description('The settings for the virtual machine')
  machine: machineSettings
  @description('The settings for the bastion')
  bastion: bastionSettings
}

type machineSettings = {
  @description('The size of the virtual machine')
  vmSize: string
  @description('The publisher of the image')
  imagePublisher: string
  @description('The offer of the image')
  imageOffer: string
  @description('The SKU of the image')
  imageSku: string
  @description('The authentication type of the virtual machine')
  authenticationType: string
}

type bastionSkuType = 'Basic' | 'Standard'

type bastionSettings = {
  @description('The name of the SKU')
  skuName: bastionSkuType
}


@description('The location of resources to deploy')
param location string

@description('Feature Flag to Enable Telemetry')
param enableTelemetry bool = false


@description('Specifies the name of the administrator account of the virtual machine.')
param vmAdminUsername string

@description('Specifies the SSH Key or password for the virtual machine. SSH key is recommended.')
@secure()
param vmAdminPasswordOrKey string

@description('Feature Flag to Enable Bastion')
param enableBastion bool

@description('The name of the Key Vault where the secret exists')
param kvName string 

@description('The Id of the virtual network')
param vnetId string

@description('The Id of the subnet for the virtual machine')
param vmSubnetId string

@description('The workspace name for diagnostics')
param workspaceName string

@description('The configuration for the manage section.')
param manageLayerConfig manageSettings


/*.______        ___           _______.___________. __    ______   .__   __. 
|   _  \      /   \         /       |           ||  |  /  __  \  |  \ |  | 
|  |_)  |    /  ^  \       |   (----`---|  |----`|  | |  |  |  | |   \|  | 
|   _  <    /  /_\  \       \   \       |  |     |  | |  |  |  | |  . `  | 
|  |_)  |  /  _____  \  .----)   |      |  |     |  | |  `--'  | |  |\   | 
|______/  /__/     \__\ |_______/       |__|     |__|  \______/  |__| \__| 
*/

module bastionHost 'br/public:avm/res/network/bastion-host:0.1.1' = if (enableBastion) {
  name: '${manageLayerConfig.sectionName}-bastion'
  params: {
    name: 'bh-${replace(manageLayerConfig.sectionName, '-', '')}${uniqueString(resourceGroup().id, manageLayerConfig.sectionName)}'
    skuName: manageLayerConfig.bastion.skuName
    vNetId: vnetId
    location: location
    enableTelemetry: enableTelemetry
  }  
}


/*
.___  ___.      ___       ______  __    __   __  .__   __.  _______ 
|   \/   |     /   \     /      ||  |  |  | |  | |  \ |  | |   ____|
|  \  /  |    /  ^  \   |  ,----'|  |__|  | |  | |   \|  | |  |__   
|  |\/|  |   /  /_\  \  |  |     |   __   | |  | |  . `  | |   __|  
|  |  |  |  /  _____  \ |  `----.|  |  |  | |  | |  |\   | |  |____ 
|__|  |__| /__/     \__\ \______||__|  |__| |__| |__| \__| |_______|                                                                
*/

resource existingVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: kvName
}

module virtualMachine './virtual_machine.bicep' = if (enableBastion) {
  name: '${manageLayerConfig.sectionName}-machine'
  params: {
    vmName: 'vm-${replace(manageLayerConfig.sectionName, '-', '')}${uniqueString(resourceGroup().id, manageLayerConfig.sectionName)}'
    vmSize: manageLayerConfig.machine.vmSize

    // Assign Tags
    tags: {
      layer: manageLayerConfig.displayName
    }

    vmSubnetId: vmSubnetId
    vmAdminUsername: vmAdminUsername
    vmAdminPasswordOrKey: empty(vmAdminPasswordOrKey) ? existingVault.getSecret('PrivateLinkSSHKey-public') : vmAdminPasswordOrKey
    workspaceName: workspaceName
    authenticationType: empty(vmAdminPasswordOrKey) ? 'sshPublicKey' : 'password'
  }
}
