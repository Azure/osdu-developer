<#
.SYNOPSIS
  Pre Provision Script
.DESCRIPTION
  This script performs pre-provisioning tasks of ensuring an ad application is properly created.
.PARAMETER SubscriptionId
  Specify a particular SubscriptionId to use. Defaults to the value of the AZURE_SUBSCRIPTION_ID environment variable if set, or null if not.
.PARAMETER ApplicationId
  Optionally specify an ApplicaitonId. Defaults to the value of the AZURE_CLIENT_ID environment variable if set, otherwise create one.
.PARAMETER AzureEnvName
  Optionally specify an Azure environment name. Defaults to the value of the AZURE_ENV_NAME environment variable if set, or "dev" if not.
.PARAMETER RequiredCliVersion
  Optionally specify the required Azure CLI version. Defaults to "2.60".
.EXAMPLE
  .\pre-provision.ps1 -SubscriptionId <SubscriptionId> -AzureEnvName <AzureEnvName> -RequiredCliVersion "2.60"
#>

#Requires -Version 7.4

param (
    [string]$SubscriptionId = $env:AZURE_SUBSCRIPTION_ID,
    [string]$ApplicationId = $env:AZURE_CLIENT_ID,
    [string]$AzureEnvName = $env:AZURE_ENV_NAME ? $env:AZURE_ENV_NAME : "dev",
    [version]$RequiredCliVersion = [version]"2.62",
    [switch]$Help
)

function Show-Help {
    Write-Output "Usage: .\hook-preprovision.ps1 [-SubscriptionId SUBSCRIPTION_ID] [-AzureEnvName AZURE_ENV_NAME] [-RequiredCliVersion REQUIRED_CLI_VERSION]"
    Write-Output "Options:"
    Write-Output " -SubscriptionId : Optionally specify a subscription ID to use. If not provided, defaults to the AZURE_SUBSCRIPTION_ID environment variable."
    Write-Output " -ApplicationId : Optionally specify an application ID to use. If not provided, creates one."
    Write-Output " -AzureEnvName : Optionally specify an Azure environment name. Defaults to 'dev' if AZURE_ENV_NAME environment variable is not set."
    Write-Output " -RequiredCliVersion : Optionally specify the required Azure CLI version. Defaults to '2.60'."
    Write-Output " -Help : Print this help message and exit"
}

function Check-AzureCliVersion {
    # Get the version of the Azure CLI
    $azVersionOutput = az version --output json | ConvertFrom-Json

    # Extract the version number
    $azVersion = $azVersionOutput.'azure-cli'
    $azVersionComparable = [version]$azVersion

    Write-Output "`n=================================================================="
    Write-Output "Azure CLI Version: $azVersionComparable"
    Write-Output "=================================================================="

    # Compare the versions
    if ($azVersionComparable -lt $RequiredCliVersion) {
        Write-Output "This script requires Azure CLI version $RequiredCliVersion or higher. You have version $azVersionComparable."
        exit 1
    }
}

function Update-AKSExtensions {
    # Check for required extensions
    $requiredExtensions = @("k8s-configuration")

    Write-Output "`n=================================================================="
    Write-Output "Azure CLI Extensions: $requiredExtensions"
    Write-Output "=================================================================="

    foreach ($extension in $requiredExtensions) {
        $azVersionOutput = az version --output json | ConvertFrom-Json
        if ($azVersionOutput.extensions.$extension) {
            Write-Output "  Found [$extension] extension. Updating..."
            az extension update --name $extension --allow-preview true --only-show-errors
        } else {
            Write-Output "  Not Found [$extension] extension. Installing..."
            az extension add --name $extension --allow-preview true --only-show-errors

            if ($?) {
                Write-Output "  [$extension] extension successfully installed"
            } else {
                Write-Output "  Failed to install [$extension] extension"
                exit 1
            }
        }
    }
}

function Check-Login {
    # Check if the user is logged in
    $user = az ad signed-in-user show --query userPrincipalName -o tsv
    $accountInfo = az account show -o json 2>$null | ConvertFrom-Json
    if ($user) {
        Write-Output "`n=================================================================="
        Write-Output "Logged in as: $user"
        Write-Output "=================================================================="
    } else {
        Write-Output "`n=================================================================="
        Write-Output "Azure CLI Login Required"
        Write-Output "=================================================================="

        az login --scope https://graph.microsoft.com//.default

        # Recheck if the user is logged in
        $accountInfo = az account show -o json | ConvertFrom-Json
        if ($accountInfo) {
            Write-Output "`n=================================================================="
            Write-Output "Logged in as: $($accountInfo.user.name)"
            Write-Output "=================================================================="
        } else {
            Write-Output "Failed to log in. Exiting."
            exit 1
        }
    }

    # Ensure the subscription ID is set
    if (-not $SubscriptionId) {
        $SubscriptionId = az account show --query id -o tsv
        azd env set AZURE_SUBSCRIPTION_ID $SubscriptionId
    }

    Write-Output "`n=================================================================="
    Write-Output "Azure Subscription: $SubscriptionId"
    Write-Output "=================================================================="
    
}

function Create-Application {
    $azureClientName = "osdu-$AzureEnvName-$SubscriptionId"
    $azureClientId = az ad app list --display-name $azureClientName --query "[0].appId" -o tsv

    if (-not $azureClientId) {
        Write-Output "`n=================================================================="
        Write-Output "Creating Application: $azureClientName"
        Write-Output "=================================================================="
        
        $jsonPayload = @"
        {
            'displayName': '$azureClientName',
            'signInAudience': 'AzureADMyOrg',
            'web': {'redirectUris': ['https://localhost:8080/'],'implicitGrantSettings': {'enableIdTokenIssuance': 'true', 'enableAccessTokenIssuance': 'true'}},
            'spa': {'redirectUris': ['https://localhost:8080/spa']},
            'requiredResourceAccess': [{'resourceAppId': '00000003-0000-0000-c000-000000000000', 'resourceAccess': [{'id': 'e1fe6dd8-ba31-4d61-89e7-88639da4683d', 'type': 'Scope'}]}]
        }
"@

        if (-not $IsWindows) {
            $jsonPayload = $jsonPayload -replace "'", '"'
        }
        # Remove whitespaces
        $jsonPayload = $jsonPayload -replace '\s+', ''

        az rest --method post `
        --url https://graph.microsoft.com/v1.0/applications `
        --body $jsonPayload -o none
      
        Start-Sleep -Seconds 30

        $ApplicationId = az ad app list --display-name $azureClientName --query "[0].appId" -o tsv
        az ad sp create --id $ApplicationId --only-show-errors

        azd env set AZURE_CLIENT_ID $ApplicationId
    } else {
        Write-Output "`n=================================================================="
        Write-Output "Azure Application: $azureClientName"
        Write-Output "=================================================================="
    }
}

function Set-EnvironmentVariables {

    Write-Output "`n=================================================================="
    Write-Output "Retrieving Application: $ApplicationId"
    Write-Output "=================================================================="

    if (-not $env:AZURE_CLIENT_PRINCIPAL_OID) {
        Write-Output "Retrieving AZURE_CLIENT_PRINCIPAL_OID..."
        $azureClientPrincipalOid = az ad sp show --id $ApplicationId --query "id" -o tsv
        echo $azureClientPrincipalOid
        azd env set AZURE_CLIENT_PRINCIPAL_OID $azureClientPrincipalOid
    }

    if (-not $env:AZURE_CLIENT_SECRET) {
        Write-Output "Retrieving AZURE_CLIENT_SECRET..."
        $azureClientSecret = az ad app credential reset --id $ApplicationId --query password --only-show-errors -o tsv
        azd env set AZURE_CLIENT_SECRET $azureClientSecret
    }

    if (-not $env:EMAIL_ADDRESS) {
        Write-Output "Retrieving User Email Address..."
        $emailAddress = az ad signed-in-user show --query userPrincipalName -o tsv
        azd env set EMAIL_ADDRESS $emailAddress
    }
}


if ($Help) {
    Show-Help
    exit 0
}

Check-AzureCliVersion
Update-AksExtensions
Check-Login
Create-Application
Set-EnvironmentVariables