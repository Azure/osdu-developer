targetScope = 'resourceGroup'

@description('Specify the Azure region to place the application definition.')
param location string = resourceGroup().location

@description('Feature Flag to Enable Telemetry')
param enableTelemetry bool = false

/////////////////
// Settings Blade 
/////////////////
@description('Specify the AD Application Client Id.')
param applicationClientId string

output applicationClientId string = applicationClientId

//*****************************************************************//
//  Common Section                                                 //
//*****************************************************************//

/////////////////////////////////
//  Configuration 
/////////////////////////////////
var commonLayerConfig = {
  name: 'common'
  displayName: 'Common Resources'
}


/*
 __   _______   _______ .__   __. .___________. __  .___________.____    ____ 
|  | |       \ |   ____||  \ |  | |           ||  | |           |\   \  /   / 
|  | |  .--.  ||  |__   |   \|  | `---|  |----`|  | `---|  |----` \   \/   /  
|  | |  |  |  ||   __|  |  . `  |     |  |     |  |     |  |       \_    _/   
|  | |  '--'  ||  |____ |  |\   |     |  |     |  |     |  |         |  |     
|__| |_______/ |_______||__| \__|     |__|     |__|     |__|         |__|     
*/

module stampIdentity 'br/public:avm/res/managed-identity/user-assigned-identity:0.1.0' = {
  name: '${commonLayerConfig.name}-user-managed-identity'
  params: {
    // Required parameters
    name: 'id-${replace(commonLayerConfig.name, '-', '')}${uniqueString(resourceGroup().id, commonLayerConfig.name)}'
    location: location
    enableTelemetry: enableTelemetry

    // Assign Tags
    tags: {
      layer: commonLayerConfig.displayName
    }
  }
}
