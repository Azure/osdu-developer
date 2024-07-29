<#
.SYNOPSIS
  Pre Deploy Script
.DESCRIPTION
  This script performs pre-deployment tasks, including checking Azure CLI version, managing Azure AD applications, and setting environment variables.
.PARAMETER SubscriptionId
  Specify a particular SubscriptionId to use.
.PARAMETER Help
  Print help message and exit.
.EXAMPLE
  .\hook-predeploy.ps1 -SubscriptionId <SubscriptionId>
#>

#Requires -Version 7.4

param (
    [string]$SubscriptionId = $env:AZURE_SUBSCRIPTION_ID,
    [switch]$Help
)

function Show-Help {
    Write-Output "Usage: .\hook-predeploy.ps1 [-SubscriptionId SUBSCRIPTION_ID]"
    Write-Output "Options:"
    Write-Output " -SubscriptionId : Specify a particular Subscription ID to use."
    Write-Output " -Help : Print this help message and exit"
}

if ($Help) {
    Show-Help
    exit 0
}

if (-not $SubscriptionId) {
    Write-Output "Error: You must provide a SubscriptionId"
    Show-Help
    exit 1
}
az account set --subscription $SubscriptionId

if (-not $env:AZURE_CLIENT_ID) {
    Write-Output 'ERROR: AZURE_CLIENT_ID not provided'
    exit 1
}

if (-not $env:AZURE_CLIENT_SECRET) {
    Write-Output 'ERROR: AZURE_CLIENT_SECRET not provided'
    exit 1
}

if (-not $env:AZURE_RESOURCE_GROUP) {
    Write-Output 'ERROR: AZURE_RESOURCE_GROUP not provided'
    exit 1
}

if (-not $env:AKS_NAME) {
    Write-Output 'ERROR: AKS_NAME not provided'
    exit 1
}

if (-not $env:AZURE_TENANT_ID) {
    $env:AZURE_TENANT_ID = az account show --query tenantId -o tsv
    azd env set AZURE_TENANT_ID $env:AZURE_TENANT_ID
}

if (-not $env:AUTH_INGRESS) {
    Write-Output "Fetching Ingress IP Address..."

    $nodeResourceGroup = az aks show -g $env:AZURE_RESOURCE_GROUP -n $env:AKS_NAME --query nodeResourceGroup -o tsv
    if ($env:INGRESS -eq 'internal') {
        $env:AUTH_INGRESS = az network lb frontend-ip list --lb-name kubernetes-internal -g $nodeResourceGroup --query '[].privateIPAddress' -o tsv
    } else {
        $env:AUTH_INGRESS = az network public-ip list -g $nodeResourceGroup --query "[?contains(name, 'kubernetes')].ipAddress" -o tsv
    }
    azd env set AUTH_INGRESS $env:AUTH_INGRESS
}

if (-not $env:AUTH_REFRESH) {
    if (-not $env:AUTH_CODE) {
        Write-Output "Error: Neither AUTH_CODE nor AUTH_REFRESH is available."
        exit 1
    } else {
        Write-Output "Getting a Refresh Token using the Authorization Code..."

        $body = @{
            grant_type    = "authorization_code"
            redirect_uri  = "https://$env:AUTH_INGRESS/auth/"
            client_id     = $env:AZURE_CLIENT_ID
            client_secret = $env:AZURE_CLIENT_SECRET
            scope         = "$env:AZURE_CLIENT_ID/.default openid profile offline_access"
            code          = $env:AUTH_CODE
        }

        try {
            $response = Invoke-RestMethod -Method Post -Uri "https://login.microsoftonline.com/$env:AZURE_TENANT_ID/oauth2/v2.0/token" -ContentType "application/x-www-form-urlencoded" -Body $body
            Write-Output "Request successful."
            $refresh_token = $response.refresh_token
            azd env set AUTH_REFRESH $refresh_token
            azd env set AUTH_CODE ""
        } catch {
            Write-Output "Request failed. Status: $($_.Exception.Response.StatusCode). Body: $($_.Exception.Response.Content)"
            exit 1
        }
    }
}

# Get the output from azd env get-values
$output = azd env get-values

# Initialize a hashtable to store the values
$envValues = @{}

# Parse the output and store the values in the hashtable
$output | ForEach-Object {
    if ($_ -match '^(.*?)="(.*)"$') {
        $name = $matches[1]
        $value = $matches[2]
        $envValues[$name] = $value
    }
}

# Assign the values to local variables
$AZURE_RESOURCE_GROUP = $envValues["AZURE_RESOURCE_GROUP"]
$AZURE_TENANT_ID = $envValues["AZURE_TENANT_ID"]
$AZURE_CLIENT_ID = $envValues["AZURE_CLIENT_ID"]
$AZURE_CLIENT_SECRET = $envValues["AZURE_CLIENT_SECRET"]
$AUTH_INGRESS = $envValues["AUTH_INGRESS"]
$AUTH_REFRESH = $envValues["AUTH_REFRESH"]

# Create the .vscode directory if it doesn't exist
New-Item -Path .vscode -ItemType Directory -Force | Out-Null

# Create the settings.json file with the environment variables
@"
{
    "rest-client.environmentVariables": {
        "${AZURE_RESOURCE_GROUP}": {
          "TENANT_ID": "${AZURE_TENANT_ID}",
          "CLIENT_ID": "${AZURE_CLIENT_ID}",
          "CLIENT_SECRET": "${AZURE_CLIENT_SECRET}",
          "HOST": "http://${AUTH_INGRESS}",
          "REFRESH_TOKEN": "${AUTH_REFRESH}",
          "DATA_PARTITION": "opendes"
        }
    }
}
"@ > .vscode/settings.json