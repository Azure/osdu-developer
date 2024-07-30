<#
.SYNOPSIS
  Post Provision Script
.DESCRIPTION
  This script performs post-provisioning tasks for waiting for software to install then updating the Application.
.PARAMETER SubscriptionId
  Specify a particular SubscriptionId to use.
.PARAMETER ResourceGroup
  Specify a particular Resource Group to use.
.PARAMETER ApplicationId
  Specify a particular Application to use.
.PARAMETER Help
  Print help message and exit.
.EXAMPLE
  .\post-provision.ps1 -SubscriptionId <SubscriptionId>
#>

#Requires -Version 7.4

param (
    [string]$SubscriptionId = $env:AZURE_SUBSCRIPTION_ID,
    [string]$ResourceGroup = $env:AZURE_RESOURCE_GROUP,
    [string]$ApplicationId = $env:AZURE_CLIENT_ID,
    [switch]$Help
)

function Show-Help {
    Write-Output "Usage: .\hook-postprovision.ps1 [-SubscriptionId SUBSCRIPTION_ID]"
    Write-Output "Options:"
    Write-Output " -SubscriptionId : Specify a particular Subscription ID to use."
    Write-Output " -ResourceGroup : Specify a particular ResourceGroup to use."
    Write-Output " -ApplicationId : Specify a particular ApplicationId to use."
    Write-Output " -Help : Print this help message and exit"
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
    Write-Output "`n=================================================================="
    Write-Output "Azure Subscription: $($SubscriptionId)"
    Write-Output "=================================================================="
    az account set --subscription $SubscriptionId
}

function Get-AKSName {
    # Check if AKS_NAME is provided, if not retrieve it
    if (-not $env:AKS_NAME) {
        Write-Output "AKS_NAME not provided. Retrieving AKS name from the resource group..."
        $aksList = az aks list -g $ResourceGroup --query '[0].name' -o tsv
        if ($aksList) {
            $global:AKS_NAME = $aksList
        } else {
            Write-Output "No AKS cluster found in the resource group."
            exit 1
        }
    } else {
        $global:AKS_NAME = $env:AKS_NAME
    }
    Write-Output "`n=================================================================="
    Write-Output "Azure Kubernetes Cluster: $global:AKS_NAME"
    Write-Output "=================================================================="
}

function Check-Software {
    $end = (Get-Date).AddMinutes(20)

    $complianceState = az k8s-configuration flux show -t managedClusters -g $ResourceGroup --cluster-name $global:AKS_NAME --name flux-system --query 'complianceState' -o tsv

    Write-Output "`n=================================================================="
    Write-Output "Software Installation: $complianceState"
    Write-Output "=================================================================="

    # If compliant right away, skip the while loop otherwise wait initially for 5 minutes.
    if ($complianceState -eq "Compliant") {
        return
    } else {
        Write-Output "Software still installing, retrying in 5 minutes."
        Start-Sleep -Seconds 300
    }

    while ((Get-Date) -lt $end) {
        $complianceState = az k8s-configuration flux show -t managedClusters -g $ResourceGroup --cluster-name $global:AKS_NAME --name flux-system --query 'complianceState' -o tsv
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

function Update-Application {
    $redirectUris = @()

    $nodeResourceGroup = az aks show -g $ResourceGroup -n $global:AKS_NAME --query nodeResourceGroup -o tsv
    $publicIp = az network public-ip list -g "$nodeResourceGroup" --query "[?contains(name, 'kubernetes')].ipAddress" -o tsv
    if ($publicIp) {
        Write-Output "`n=================================================================="
        Write-Output "Adding Public Web Endpoint: $publicIp"
        Write-Output "=================================================================="
        $redirectUris += "https://$publicIp/auth/"
    }
    azd env set INGRESS_EXTERNAL "https://$publicIp/auth/"

    $privateIp = az network lb frontend-ip list --lb-name kubernetes-internal -g "$nodeResourceGroup" --query [].privateIPAddress -o tsv
    if ($privateIp) {
        Write-Output "`n=================================================================="
        Write-Output "Adding Private Web Endpoint: $privateIp"
        Write-Output "=================================================================="
        $redirectUris += "https://$privateIp/auth/"
    }
    azd env set INGRESS_INTERNAL "https://$privateIp/auth/"

    $azureClientOid = az ad app show --id $ApplicationId --query id -o tsv
    Write-Output "`n=================================================================="
    Write-Output "Updating AD Application (OID): $azureClientOid"
    Write-Output "=================================================================="

    if ($redirectUris.Count -gt 0) {
        Write-Output "Adding Redirect URIs: $($redirectUris -join ', ')"

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

        if (-not $IsWindows) {
            $jsonPayload = $jsonPayload -replace "'", '"'
        }
        # Remove whitespaces
        $jsonPayload = $jsonPayload -replace '\s+', ''

        az rest --method PATCH `
            --url "https://graph.microsoft.com/v1.0/applications/$azureClientOid" `
            --body $jsonPayload
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

if (-not $ResourceGroup) {
    Write-Output "Error: You must provide a ResourceGroup"
    Show-Help
    exit 1
}

if (-not $ApplicationId) {
    Write-Output "Error: You must provide an ApplicationId"
    Show-Help
    exit 1
}

Check-Login
Get-AKSName
Check-Software
Update-Application

Start-Sleep -Seconds 30

# Open the web browser
$os = ($PSVersionTable.OS).Split(' ')[0]
$url = [string]((azd env get-values | Where-Object { $_ -match "INGRESS_EXTERNAL" }) -split '=')[1].Trim()
$url = $url -replace '"', ''

if ($os -ne "Darwin") {
    $url = $url -replace '^https:', 'http:'
}

if ($IsWindows) {
    Start-Process $url
} else {
    powershell.exe /c start "$url"
}