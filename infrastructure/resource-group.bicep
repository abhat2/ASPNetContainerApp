targetScope = 'subscription'

var location = deployment().location
var resourceGroupName = 'rg-asp-container-app'
 
resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroupName
  location: location
  tags: {
    Project: 'ASP Container App'
    ResourceGroup: resourceGroupName
  }
}

output resourceGroupName string = resourceGroup.name
output resourceGroupId string = resourceGroup.id
