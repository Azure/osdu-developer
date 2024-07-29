<#
.SYNOPSIS
  Post Provision Script
.DESCRIPTION
  This script performs post-provisioning tasks, including checking Azure CLI version, managing Azure AD applications, and setting environment variables.
.PARAMETER SubscriptionId
  Specify a particular SubscriptionId to use.
.PARAMETER Help
  Print help message and exit.
.EXAMPLE
  .\hook-postprovision.ps1 -SubscriptionId <SubscriptionId>
#>

param (
    [string]$SubscriptionId = $env:AZURE_SUBSCRIPTION_ID,
    [switch]$Help
)

function Show-Help {
    Write-Output "Usage: .\hook-postprovision.ps1 [-SubscriptionId SUBSCRIPTION_ID]"
    Write-Output "Options:"
    Write-Output " -SubscriptionId : Specify a particular Subscription ID to use."
    Write-Output " -Help : Print this help message and exit"
}

function Check-Login {
    # Check if the user is logged in
    $accountInfo = az account show -o json 2>$null | ConvertFrom-Json
    if ($accountInfo) {
        Write-Output "`n=================================================================="
        Write-Output "Logged in as: $($accountInfo.user.name)"
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
    Write-Output "`n=================================================================="
    Write-Output "Azure Subscription: $($SubscriptionId)"
    Write-Output "=================================================================="
    az account set --subscription $SubscriptionId
}

function Check-FluxCompliance {
    $end = (Get-Date).AddMinutes(20)

    Write-Output "Checking Software Installation..."
    while ((Get-Date) -lt $end) {
        $complianceState = az k8s-configuration flux show -t managedClusters -g $env:AZURE_RESOURCE_GROUP --cluster-name $env:AKS_NAME --name flux-system --query 'complianceState' -o tsv
        Write-Output "Current Software State: $complianceState"
        if ($complianceState -eq "Compliant") {
            Write-Output "Software has been installed."
            break
        } else {
            Write-Output "Software still installing, retrying in 1 minute."
            Start-Sleep -Seconds 60
        }
    }

    if ((Get-Date) -ge $end) {
        Write-Output "Software check timed out after 20 minutes."
    }
}

function Add-RedirectUris {
    $redirectUris = @()

    $nodeResourceGroup = az aks show -g $env:AZURE_RESOURCE_GROUP -n $env:AKS_NAME --query nodeResourceGroup -o tsv
    $publicIp = az network public-ip list -g "$nodeResourceGroup" --query "[?contains(name, 'kubernetes')].ipAddress" -o tsv
    if ($publicIp) {
        Write-Output "Adding Public Web Endpoint: $publicIp"
        $redirectUris += "https://$publicIp/auth/"
    }
    azd env set INGRESS_EXTERNAL "https://$publicIp/auth/"

    $privateIp = az network lb frontend-ip list --lb-name kubernetes-internal -g "$nodeResourceGroup" --query [].privateIPAddress -o tsv
    if ($privateIp) {
        Write-Output "Adding Private Web Endpoint: $privateIp"
        $redirectUris += "https://$privateIp/auth/"
    }
    azd env set INGRESS_INTERNAL "https://$privateIp/auth/"

    $azureClientOid = az ad app show --id $env:AZURE_CLIENT_ID --query id -o tsv

    if ($redirectUris.Count -gt 0) {
        Write-Output "=================================================================="
        Write-Output "Adding Redirect URIs: $($redirectUris -join ', ')"
        Write-Output "=================================================================="

        $webUris = $($redirectUris | ConvertTo-Json -Compress)
        $spaUris = $($redirectUris | ForEach-Object { "$_`/spa/" } | ConvertTo-Json -Compress)

        # Replace double quotes with single quotes in the JSON strings
        $webUris = $webUris -replace '"', "'"
        $spaUris = $spaUris -replace '"', "'"

        $jsonPayload = @"
        {
            'web': {'redirectUris': $($webUris),'implicitGrantSettings': {'enableAccessTokenIssuance': false,'enableIdTokenIssuance': false}},
            'spa': {'redirectUris': $($spaUris)}
        }
"@
        # Remove whitespaces
        $jsonPayloadCleaned = $jsonPayload -replace '\s+', ''

        az rest --method PATCH `
            --url "https://graph.microsoft.com/v1.0/applications/$azureClientOid" `
            --headers '{\"Content-Type\": \"application/json\"}' `
            --body $jsonPayloadCleaned
    }
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

Check-Login
Check-FluxCompliance
Add-RedirectUris

Start-Sleep -Seconds 30
Start-Process ((azd env get-values | Where-Object { $_ -match "INGRESS_EXTERNAL" }) -split '=')[1].Trim()