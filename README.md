# ASPNetContainerApp
This is a repository which contains the scripts and code to deploy a containerized ASP.NET app in Azure.

## Prerequisites
- Access to an Azure subscription with sufficient permissions
- Azure DevOps
- Service connections for GitHub and Azure subscription in Azure DevOps
- IDE such as Visual Studio Code and Visual Studio
- Bicep template library
- Azure PowerShell
- .NET version 8
- Docker desktop
- Microsoft Hyper-V enabled locally

## Instructions
1. Clone repository.
2. Under the infrastructure folder open the PowerShell script - `deploy.ps1`.
3. In a PowerShell terminal run the following command to run the deployment script. You will need to pass in your tenant ID and subscription ID as parameters.
```powershell
.\infrastructure\deploy.ps1 -TenantId "your tenant ID" -SubscriptionId "your subscription ID"
```
4. In the Azure Portal, verify the following services have been created:
- Log workspace
- Storage account (collect logs and metrics)
- Key vault
- Azure container registry
- App service plan (Windows containers)
- Application insights
- App service (Windows container)
5. Open the solution file and ensure the app can be run locally. The app is a basic ASP.NET application from Microsoft.
6. In Azure DevOps, create a variable group named `Container_App_Variables` with the following variables:
```
- appName - app-asp-container-app
- azureSubscription - name of service connection for Azure subscription
- containerRegistry - acraspcontainerapp
- containerRegistryPassword - admin user password for container registry
- dockerRegistryServiceConnection - name of service connection to Azure container repository
- imageRepository - aspcontainerapp
- resourceGroup - rg-asp-container-app
```
7. In Azure DevOps, create an environment name `Production` and set up approvals.
8. In Azure Devops, create a pipeline which points to your repository as the source. Refer to the pipeline YML file in the repository - `azure-pipelines.yml`.
9. Save and run the pipeline. You will be required to provide an approval for the deploying to production stage.
10. Verify that the pipeline runs successfully.
11. In Azure portal, go to the Azure container registry and verify that a repository has been created with an image.
12. In Azure portal, go to the app service and verify that the staging and production URLs display the ASP.NET app.

## Improvements
- Purchase a domain and create an SSL certificate in Azure Key Vault.
- Add a custom domain and attach the certificate to the app service.
- Use a managed identity in the app service to pull images from the Azure container registry.