<#
.SYNOPSIS
  Post Provision Script
.DESCRIPTION
  This script performs post-provisioning tasks, waiting for software to install, and then updating the Application.
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
    [ValidateNotNullOrEmpty()]
    [string]$SubscriptionId = $env:AZURE_SUBSCRIPTION_ID,
    
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroup = $env:AZURE_RESOURCE_GROUP,
    
    [ValidateNotNullOrEmpty()]
    [string]$ApplicationId = $env:AZURE_CLIENT_ID,
    
    [switch]$Help
)

function Show-Help {
    Write-Host "Usage: .\hook-postprovision.ps1 [-SubscriptionId SUBSCRIPTION_ID]"
    Write-Host "Options:"
    Write-Host " -SubscriptionId : Specify a particular Subscription ID to use."
    Write-Host " -ResourceGroup : Specify a particular ResourceGroup to use."
    Write-Host " -ApplicationId : Specify a particular ApplicationId to use."
    Write-Host " -Help : Print this help message and exit"
}

function Set-Login {
    try {
        # Check if the user is logged in
        $user = az ad signed-in-user show --query mail -o tsv
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
        Write-Host "`n=================================================================="
        Write-Host "Azure Subscription: $($SubscriptionId)"
        Write-Host "=================================================================="
        az account set --subscription $SubscriptionId
    } catch {
        Write-Host "Error during login check: $_"
        exit 1
    }
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
    Write-Output "`n=================================================================="
    Write-Output "Azure Kubernetes Cluster: $env:AKS_NAME"
    Write-Output "=================================================================="
}

function Get-Software {
    try {
        $complianceState = az k8s-configuration flux show -t managedClusters -g $ResourceGroup --cluster-name $AKS_NAME --name flux-system --query 'complianceState' -o tsv
        Write-Host "`n=================================================================="
        Write-Host "Software Installation: $complianceState"
        Write-Host "=================================================================="
        return $complianceState
    } catch {
        Write-Host "Error during software check: $_"
        exit 1
    }
}

function Get-Software-Original {
    $end = (Get-Date).AddMinutes(35)
    try {
        $complianceState = az k8s-configuration flux show -t managedClusters -g $ResourceGroup --cluster-name $AKS_NAME --name flux-system --query 'complianceState' -o tsv
        Write-Host "`n=================================================================="
        Write-Host "Software Installation: $complianceState"
        Write-Host "=================================================================="
        # If compliant right away, skip the while loop otherwise wait initially for 5 minutes.
        if ($complianceState -eq "Compliant") {
            return
        } else {
            Write-Host "  Software installing, retry in 10 minutes."
            Start-Sleep -Seconds 300
        }
        while ((Get-Date) -lt $end) {
            $complianceState = az k8s-configuration flux show -t managedClusters -g $ResourceGroup --cluster-name $AKS_NAME --name flux-system --query 'complianceState' -o tsv
            Write-Host "  Current Software State: $complianceState"
            if ($complianceState -eq "Compliant") {
                Write-Host "  Software has been installed."
                break
            } else {
                Write-Host "  Software installing, retry in 2 minute."
                Start-Sleep -Seconds 120
            }
        }
        if ((Get-Date) -ge $end) {
            Write-Host "  Software check timed out - 35 minutes."
        }
    } catch {
        Write-Host "Error during software check: $_"
        exit 1
    }
}

function Update-Application {
    try {
        $redirectUris = @()
        $nodeResourceGroup = az aks show -g $ResourceGroup -n $AKS_NAME --query nodeResourceGroup -o tsv
        $publicIp = az network public-ip list -g "$nodeResourceGroup" --query "[?contains(name, 'kubernetes')].ipAddress" -o tsv
        if ($publicIp) {
            Write-Host "`n=================================================================="
            Write-Host "Adding Public Web Endpoint: $publicIp"
            Write-Host "=================================================================="
            $redirectUris += "https://$publicIp/auth/"
        }
        azd env set INGRESS_EXTERNAL "https://$publicIp/auth/"
        $privateIp = az network lb frontend-ip list --lb-name kubernetes-internal -g "$nodeResourceGroup" --query [].privateIPAddress -o tsv
        if ($privateIp) {
            Write-Host "`n=================================================================="
            Write-Host "Adding Private Web Endpoint: $privateIp"
            Write-Host "=================================================================="
            $redirectUris += "https://$privateIp/auth/"
        }
        azd env set INGRESS_INTERNAL "https://$privateIp/auth/"
        $azureClientOid = az ad app show --id $ApplicationId --query id -o tsv
        Write-Host "`n=================================================================="
        Write-Host "Updating AD Application (OID): $azureClientOid"
        Write-Host "=================================================================="
        if ($redirectUris.Count -gt 0) {
            Write-Host "  Adding Redirect URIs: $($redirectUris -join ', ')"
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
                --headers 'Content-Type=application/json' `
                --body $jsonPayload
        }
    } catch {
        Write-Host "Error during application update: $_"
        exit 1
    }
}

# Main script execution
if ($Help) {
    Show-Help
    exit 0
}

if (-not $SubscriptionId) {
    Write-Host "Error: You must provide a SubscriptionId"
    Show-Help
    exit 1
}

if (-not $ResourceGroup) {
    Write-Host "Error: You must provide a ResourceGroup"
    Show-Help
    exit 1
}

if (-not $ApplicationId) {
    Write-Host "Error: You must provide an ApplicationId"
    Show-Help
    exit 1
}

do {
    Set-Login
    $AKS_NAME = Get-AKSName
    $complianceState = Get-Software

    if ($complianceState -ne "Compliant") {
        Write-Host "  Software is not compliant yet. Retrying in 5 minutes."
        Start-Sleep -Seconds 300
    }
} while ($complianceState -ne "Compliant")

Update-Application
Start-Sleep -Seconds 30

# Open the web browser
$os = ($PSVersionTable.OS).Split(' ')[0]
$url = [string]((azd env get-values | Where-Object { $_ -match "INGRESS_EXTERNAL" }) -split '=')[1].Trim()
$url = $url -replace '"', ''
### --> This is the https hack.
# if ($os -ne "Darwin") {
#     $url = $url -replace '^https:', 'http:'
# }
if ($IsWindows) {
    Start-Process $url
} else {
    if ($os -eq "Darwin" -or $os -eq "Ubuntu") {
        open $url
    } else {
        if (Get-Command powershell.exe -ErrorAction SilentlyContinue) {
            powershell.exe /c start "$url"
        } else {
            Write-Host "Please manually open the URL: $url"
        }
    }
}
