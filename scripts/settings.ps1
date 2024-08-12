<#
.SYNOPSIS
  Token Setting Script
.DESCRIPTION
  This script performs the tasks of getting a Refresh Token and creating the .vscode settings.json file.
.PARAMETER SubscriptionId
  Specify a particular SubscriptionId to use.
.PARAMETER ApplicationId
  Specify the ApplicationId to use.
.PARAMETER ApplicationSecret
  Specify the ApplicationSecret to use.
.PARAMETER ResourceGroup
  Specify the ResourceGroup to use.
.PARAMETER Help
  Print help message and exit.
.NOTES
  The AUTH_CODE environment variable must be set for the script to run successfully. This variable is required to obtain a Refresh Token.
.EXAMPLE
  .\settings.ps1 -SubscriptionId <SubscriptionId> -ApplicationId <ApplicationId> -ApplicationSecret <ApplicationSecret> -ResourceGroup <ResourceGroup>
#>

#Requires -Version 7.4

param (
    [ValidateNotNullOrEmpty()]
    [string]$SubscriptionId = $env:AZURE_SUBSCRIPTION_ID,

    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroup = $env:AZURE_RESOURCE_GROUP,

    [ValidateNotNullOrEmpty()]
    [string]$ApplicationId = $env:AZURE_CLIENT_ID,

    [ValidateNotNullOrEmpty()]
    [string]$ApplicationSecret = $env:AZURE_CLIENT_SECRET,

    [switch]$Help
)

function Show-Help {
    Write-Host "Usage: .\settings.ps1 [-SubscriptionId SUBSCRIPTION_ID] [-ApplicationId APPLICATION_ID] [-ApplicationSecret APPLICATION_SECRET] [-ResourceGroup RESOURCE_GROUP]"
    Write-Host "Options:"
    Write-Host " -SubscriptionId : Specify a particular Subscription ID to use."
    Write-Host " -ResourceGroup : Specify the Resource Group to use."
    Write-Host " -ApplicationId : Specify the Application ID to use."
    Write-Host " -ApplicationSecret : Specify the Application Secret to use."
    Write-Host " -Help : Print this help message and exit"
}

function Get-AKSName {
    try {
        # Check if AKS_NAME is provided, if not retrieve it
        if (-not $env:AKS_NAME) {
            Write-Host "  AKS_NAME not provided. Retrieving AKS name."
            $aksList = az aks list -g $ResourceGroup --query '[0].name' -o tsv
            if ($aksList) {
                return $aksList
            } else {
                Write-Host "  No AKS cluster found in the resource group."
                exit 1
            }
        } else {
            return $env:AKS_NAME
        }
    } catch {
        Write-Host "Error retrieving AKS name: $_"
        exit 1
    }
}

function Set-AuthIngress {
    if (-not $env:AUTH_INGRESS) {
        Write-Host "`n=================================================================="
        Write-Host "Azure Kubernetes Cluster: $AKS_NAME"
        Write-Host "=================================================================="
        Write-Host "  Fetching Ingress IP Address..."

        $nodeResourceGroup = az aks show -g $ResourceGroup -n $AKS_NAME --query nodeResourceGroup -o tsv
        if ($env:INGRESS -eq 'internal') {
            $env:AUTH_INGRESS = az network lb frontend-ip list --lb-name kubernetes-internal -g $nodeResourceGroup --query '[].privateIPAddress' -o tsv
        } else {
            $env:AUTH_INGRESS = az network public-ip list -g $nodeResourceGroup --query "[?contains(name, 'kubernetes')].ipAddress" -o tsv
        }
        azd env set AUTH_INGRESS $env:AUTH_INGRESS
    } else {
        Write-Host "`n=================================================================="
        Write-Host "Ingress IP: $env:AUTH_INGRESS"
        Write-Host "=================================================================="
    }
}

function Get-RefreshToken {

    if (-not $env:AUTH_REFRESH) {
        if (-not $env:AUTH_CODE) {
            Write-Output "Error: Neither AUTH_CODE nor AUTH_REFRESH is available."
            exit 1
        } else {
            Write-Output "`n=================================================================="
            Write-Output "Azure Application: $ApplicationId"
            Write-Output "=================================================================="
            Write-Output "Getting a Refresh Token using the Authorization Code..."

            $body = @{
                grant_type    = "authorization_code"
                redirect_uri  = "https://$env:AUTH_INGRESS/auth/"
                client_id     = $ApplicationId
                client_secret = $ApplicationSecret
                scope         = "$ApplicationId/.default openid profile offline_access"
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
                Write-Output "Error Message: $($_.Exception.Message)"
                Write-Output "Response Content: $($_.Exception.Response.Content.ReadAsStringAsync().Result)"
                exit 1
            }
        }
    }
}

function New-VSCodeSettings {
    Write-Host "`n=================================================================="
    Write-Host "Creating File: .vscode/settings.json"
    Write-Host "=================================================================="

    $output = azd env get-values
    $envValues = @{}
    $output | ForEach-Object {
        if ($_ -match '^(.*?)="(.*)"$') {
            $name = $matches[1]
            $value = $matches[2]
            $envValues[$name] = $value
        }
    }

    $AZURE_TENANT_ID = $envValues["AZURE_TENANT_ID"]
    $AUTH_INGRESS = $envValues["AUTH_INGRESS"]
    $AUTH_REFRESH = $envValues["AUTH_REFRESH"]

    New-Item -Path .vscode -ItemType Directory -Force | Out-Null

    @"
{
    "rest-client.environmentVariables": {
        "${ResourceGroup}": {
          "TENANT_ID": "${AZURE_TENANT_ID}",
          "CLIENT_ID": "${ApplicationId}",
          "CLIENT_SECRET": "${ApplicationSecret}",
          "HOST": "http://${AUTH_INGRESS}",
          "REFRESH_TOKEN": "${AUTH_REFRESH}",
          "DATA_PARTITION": "opendes"
        }
    },
    "files.exclude": {
      "**/.git": true,
      "**/.DS_Store": true,
      "**/Thumbs.db": true,
      "src/lib/os-core-common": true,
      "src/lib/os-core-lib-azure": true,
      "src/lib/os-core-lib-azure-spring-6": true,
      "src/core/partition": true,
      "src/core/entitlements": true,
      "src/core/legal": true,
      "src/core/schema-service": true,
      "src/core/indexer-service": true,
      "src/core/indexer-queue": true,
      "src/core/storage": true,
      "src/core/search-service": true,
      "src/core/file": true,
      "src/reference/unit-service": true,
      "src/reference/crs-catalog-service": true,
      "src/reference/crs-conversion-service": true
    }
}
"@ > .vscode/settings.json
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

if (-not $ApplicationId) {
    Write-Output 'ERROR: ApplicationId not provided'
    exit 1
}

if (-not $ApplicationSecret) {
    Write-Output 'ERROR: ApplicationSecret not provided'
    exit 1
}

if (-not $ResourceGroup) {
    Write-Output 'ERROR: ResourceGroup not provided'
    exit 1
}

if (-not $env:AZURE_TENANT_ID) {
    $env:AZURE_TENANT_ID = az account show --query tenantId -o tsv
    azd env set AZURE_TENANT_ID $env:AZURE_TENANT_ID
}

# Ensure the Subscription is set for the Azure CLI
az account set --subscription $SubscriptionId
Write-Host "`n=================================================================="
Write-Host "Azure Subscription: $SubscriptionId"
Write-Host "=================================================================="

$AKS_NAME = Get-AKSName
Set-AuthIngress
Get-RefreshToken
New-VSCodeSettings
