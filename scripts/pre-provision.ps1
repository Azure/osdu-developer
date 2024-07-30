<#
.SYNOPSIS
  Pre Provision Script
.DESCRIPTION
  This script performs pre-provisioning tasks, ensuring an AD application is properly created.
.PARAMETER SubscriptionId
  Specify a particular SubscriptionId to use. Defaults to the value of the AZURE_SUBSCRIPTION_ID environment variable if set, or null if not.
.PARAMETER ApplicationId
  Optionally specify an ApplicationId. Defaults to the value of the AZURE_CLIENT_ID environment variable if set, otherwise creates one.
.PARAMETER AzureEnvName
  Optionally specify an Azure environment name. Defaults to the value of the AZURE_ENV_NAME environment variable if set, or "dev" if not.
.PARAMETER RequiredCliVersion
  Optionally specify the required Azure CLI version. Defaults to "2.60".
.EXAMPLE
  .\pre-provision.ps1 -SubscriptionId <SubscriptionId> -AzureEnvName <AzureEnvName> -RequiredCliVersion "2.60"
#>

#Requires -Version 7.4

param (
    [ValidateNotNullOrEmpty()]
    [string]$SubscriptionId = $env:AZURE_SUBSCRIPTION_ID,
    
    [ValidateNotNullOrEmpty()]
    [string]$ApplicationId = $env:AZURE_CLIENT_ID,
    
    [string]$AzureEnvName = $env:AZURE_ENV_NAME ? $env:AZURE_ENV_NAME : "dev",
    
    [version]$RequiredCliVersion = [version]"2.60",
    
    [switch]$Help
)

function Show-Help {
    Write-Host "Usage: .\hook-preprovision.ps1 [-SubscriptionId SUBSCRIPTION_ID] [-AzureEnvName AZURE_ENV_NAME] [-RequiredCliVersion REQUIRED_CLI_VERSION]"
    Write-Host "Options:"
    Write-Host " -SubscriptionId : Optionally specify a subscription ID to use. If not provided, defaults to the AZURE_SUBSCRIPTION_ID environment variable."
    Write-Host " -ApplicationId : Optionally specify an application ID to use. If not provided, creates one."
    Write-Host " -AzureEnvName : Optionally specify an Azure environment name. Defaults to 'dev' if AZURE_ENV_NAME environment variable is not set."
    Write-Host " -RequiredCliVersion : Optionally specify the required Azure CLI version. Defaults to '2.60'."
    Write-Host " -Help : Print this help message and exit"
}

function Check-AzureCliVersion {
    try {
        # Get the version of the Azure CLI
        $azVersionOutput = az version --output json | ConvertFrom-Json
        $azVersion = $azVersionOutput.'azure-cli'
        $azVersionComparable = [version]$azVersion

        Write-Host "`n=================================================================="
        Write-Host "Azure CLI Version: $azVersionComparable"
        Write-Host "=================================================================="

        # Compare the versions
        if ($azVersionComparable -lt $RequiredCliVersion) {
            Write-Host "This script requires Azure CLI version $RequiredCliVersion or higher. You have version $azVersionComparable."
            exit 1
        }
    } catch {
        Write-Host "Error checking Azure CLI version: $_"
        exit 1
    }
}

function Update-AksExtensions {
    try {
        # Check for required extensions
        $requiredExtensions = @("k8s-configuration")

        Write-Host "`n=================================================================="
        Write-Host "Azure CLI Extensions: $requiredExtensions"
        Write-Host "=================================================================="

        foreach ($extension in $requiredExtensions) {
            $azVersionOutput = az version --output json | ConvertFrom-Json
            if ($azVersionOutput.extensions.$extension) {
                Write-Host "  Found [$extension] extension. Updating..."
                az extension update --name $extension --allow-preview true --only-show-errors
            } else {
                Write-Host "  Not Found [$extension] extension. Installing..."
                az extension add --name $extension --allow-preview true --only-show-errors

                if ($?) {
                    Write-Host "  [$extension] extension successfully installed"
                } else {
                    Write-Host "  Failed to install [$extension] extension"
                    exit 1
                }
            }
        }
    } catch {
        Write-Host "Error updating Azure CLI extensions: $_"
        exit 1
    }
}

function Check-Login {
    try {
        # Check if the user is logged in
        $user = az ad signed-in-user show --query userPrincipalName -o tsv
        $accountInfo = az account show -o json 2>$null | ConvertFrom-Json
        if ($user) {
            Write-Host "`n=================================================================="
            Write-Host "Logged in as: $user"
            Write-Host "=================================================================="
        } else {
            Write-Host "`n=================================================================="
            Write-Host "Azure CLI Login Required"
            Write-Host "=================================================================="
            az login --scope https://graph.microsoft.com//.default
            # Recheck if the user is logged in
            $accountInfo = az account show -o json | ConvertFrom-Json
            if ($accountInfo) {
                Write-Host "`n=================================================================="
                Write-Host "Logged in as: $($accountInfo.user.name)"
                Write-Host "=================================================================="
            } else {
                Write-Host "  Failed to log in. Exiting."
                exit 1
            }
        }
        # Ensure the subscription ID is set
        if (-not $SubscriptionId) {
            $SubscriptionId = az account show --query id -o tsv
            azd env set AZURE_SUBSCRIPTION_ID $SubscriptionId
        }

        Write-Host "`n=================================================================="
        Write-Host "Azure Subscription: $SubscriptionId"
        Write-Host "=================================================================="
    } catch {
        Write-Host "Error during login check: $_"
        exit 1
    }
}

function Create-Application {
    try {
        $azureClientName = "osdu-$AzureEnvName-$SubscriptionId"
        $azureClientId = az ad app list --display-name $azureClientName --query "[0].appId" -o tsv

        if (-not $azureClientId) {
            Write-Host "`n=================================================================="
            Write-Host "Creating Application: $azureClientName"
            Write-Host "=================================================================="
            
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
            Write-Host "`n=================================================================="
            Write-Host "Azure Application: $azureClientName"
            Write-Host "=================================================================="
        }
    } catch {
        Write-Host "Error creating application: $_"
        exit 1
    }
}

function Set-EnvironmentVariables {
    try {
        Write-Host "`n=================================================================="
        Write-Host "Retrieving Application: $ApplicationId"
        Write-Host "=================================================================="

        if (-not $env:AZURE_CLIENT_PRINCIPAL_OID) {
            Write-Host "  Retrieving AZURE_CLIENT_PRINCIPAL_OID..."
            $azureClientPrincipalOid = az ad sp show --id $ApplicationId --query "id" -o tsv
            echo $azureClientPrincipalOid
            azd env set AZURE_CLIENT_PRINCIPAL_OID $azureClientPrincipalOid
        }

        if (-not $env:AZURE_CLIENT_SECRET) {
            Write-Host "  Retrieving AZURE_CLIENT_SECRET..."
            $azureClientSecret = az ad app credential reset --id $ApplicationId --query password --only-show-errors -o tsv
            azd env set AZURE_CLIENT_SECRET $azureClientSecret
        }

        if (-not $env:EMAIL_ADDRESS) {
            Write-Host "  Retrieving User Email Address..."
            $emailAddress = az ad signed-in-user show --query userPrincipalName -o tsv
            azd env set EMAIL_ADDRESS $emailAddress
        }
    } catch {
        Write-Host "Error setting environment variables: $_"
        exit 1
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
