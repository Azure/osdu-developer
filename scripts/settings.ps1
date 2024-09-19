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

function New-EnvFile {
    Write-Host "`n=================================================================="
    Write-Host "Creating File: ../src/.envrc"
    Write-Host "=================================================================="

    $templatePath = "./scripts/envrc_template"
    $outputPath = "./src/.envrc"

    if (-not (Test-Path $templatePath)) {
        Write-Host "Error: Template file not found at $templatePath"
        exit 1
    }

    $content = Get-Content $templatePath -Raw

    $variablePattern = '%(\w+)%'
    $foundMatches = [regex]::Matches($content, $variablePattern)

    foreach ($match in $foundMatches) {
        $variableName = $match.Groups[1].Value
        $environmentValue = [Environment]::GetEnvironmentVariable($variableName)

        if ($null -eq $environmentValue) {
            Write-Host "Warning: Environment variable $variableName not found. Leaving as is in the output."
        } else {
            $content = $content -replace "%$variableName%", $environmentValue
        }
    }

    New-Item -Path (Split-Path $outputPath) -ItemType Directory -Force | Out-Null
    $content | Out-File -FilePath $outputPath -Encoding utf8

    Write-Host "File created successfully at $outputPath"
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
      "src/core/ingestion-workflow": true,
      "src/reference/unit-service": true,
      "src/reference/crs-catalog-service": true,
      "src/reference/crs-conversion-service": true
    }
}
"@ > .vscode/settings.json
}

function New-YamlFile {
    Write-Host "`n=================================================================="
    Write-Host "Processing YAML file: ./scripts/template.yaml"
    Write-Host "=================================================================="

    # Read the YAML file
    $yamlContent = Get-Content "./scripts/template.yaml" -Raw

    # Find all levels of nodes using regex
    $nodeMatches = [regex]::Matches($yamlContent, '(?m)^(\s*)(\w+):(.*)')

    # Initialize variables
    $currentLevel = -1
    $nodePath = @()
    $osduGroupNode = ""
    $serviceNameNode = ""  # This will hold the service name (e.g., partition, entitlements, unit)
    $projectTaskNode = ""  # This will be RUN or TEST
    $contentBuffer = @()
    $captureContent = $false

    # Function to write buffered content to file
    function WriteBufferToFile {
        if ($captureContent -and $contentBuffer.Count -gt 0) {
            # Changed the order here: project task first, then service name
            $outputFileName = "${projectTaskNode}_${serviceNameNode}.yaml".ToLower()
            $outputPath = Join-Path $outputDirectory $outputFileName
            $contentBuffer | Out-File -FilePath $outputPath -Encoding utf8
            $contentBuffer.Clear()
        }
    }

    # Function to replace environment variable placeholders
    function Replace-EnvironmentVariables($value) {
        return [regex]::Replace($value, '%(\w+)%', {
            param($match)
            $envVar = $match.Groups[1].Value
            $envValue = [Environment]::GetEnvironmentVariable($envVar)
            if ($null -ne $envValue) {
                return $envValue
            }
            return $match.Value  # Return original value if environment variable not found
        })
    }

    # Process each line in the YAML file
    foreach ($match in $nodeMatches) {
        $indent = $match.Groups[1].Value.Length / 2  # Convert indent to level
        $nodeName = $match.Groups[2].Value  # Keep original case
        $nodeValue = $match.Groups[3].Value.Trim()

        # Process top-level categories in the YAML (e.g., CORE, REFERENCE)
        if ($indent -eq 0) {
            WriteBufferToFile  # Write any existing buffer
            $currentLevel = 0
            $nodePath = @($nodeName)
            $osduGroupNode = $nodeName
            
            # Create output directory for the new OSDU group node
            $outputDirectory = "./src/$osduGroupNode".ToLower()
            New-Item -ItemType Directory -Force -Path $outputDirectory | Out-Null

            $captureContent = $false
        }
        # Process node at a deeper level than current
        elseif ($indent -gt $currentLevel) {
            if ($indent -eq 1) {
                # This is where services (partition, entitlements, unit, etc.) are parsed
                $serviceNameNode = $nodeName
            }
            elseif ($indent -eq 2) {
                WriteBufferToFile  # Write any existing buffer
                $projectTaskNode = $nodeName  # This will be RUN or TEST
                $captureContent = $true  # Start capturing content for this node
            }
            $currentLevel = $indent
            $nodePath += $nodeName
        }
        # Process node at the same level
        elseif ($indent -eq $currentLevel) {
            if ($indent -eq 1) {
                # This is also where services are parsed when moving to a new service at the same level
                WriteBufferToFile  # Write any existing buffer
                $serviceNameNode = $nodeName
            }
            elseif ($indent -eq 2) {
                WriteBufferToFile  # Write any existing buffer
                $projectTaskNode = $nodeName  # This will be RUN or TEST
                $captureContent = $true  # Start capturing content for this node
            }
            $nodePath[-1] = $nodeName
        }
        # Process node at a higher level (less indented)
        else {
            WriteBufferToFile  # Write any existing buffer
            $nodePath = $nodePath[0..$indent] + @($nodeName)
            $currentLevel = $indent
            if ($currentLevel -eq 1) {
                # This is where services are parsed when moving back up to the service level
                $serviceNameNode = $nodeName
            }
            elseif ($currentLevel -eq 2) {
                $projectTaskNode = $nodeName  # This will be RUN or TEST
                $captureContent = $true  # Start capturing content for this node
            }
            else {
                $captureContent = $false
            }
        }

        # Capture content for child nodes of RUN and TEST (indent level 3)
        if ($captureContent -and $indent -eq 3) {
            # This is where individual environment settings (key-value pairs) are processed
            # These are the actual environment settings that will be written to the file
            if ($nodeValue -ne "") {
                $replacedValue = Replace-EnvironmentVariables $nodeValue
                $contentBuffer += "{0}: {1}" -f $nodeName, $replacedValue
            } else {
                $contentBuffer += "{0}:" -f $nodeName
            }
        }
    }

    # Write the last file if there's content in the buffer
    WriteBufferToFile
}

function New-ServiceEnvFile {
    Write-Host "`n=================================================================="
    Write-Host "Processing YAML file: ./scripts/template.yaml"
    Write-Host "=================================================================="

    # Read the YAML file
    $yamlContent = Get-Content "./scripts/template.yaml" -Raw

    # Find all levels of nodes using regex
    $nodeMatches = [regex]::Matches($yamlContent, '(?m)^(\s*)(\w+):(.*)')

    # Initialize variables
    $currentLevel = -1
    $nodePath = @()
    $osduGroupNode = ""
    $serviceNameNode = ""
    $projectTaskNode = ""
    $contentBuffer = @()
    $captureContent = $false

    # Function to write buffered content to file
    function WriteBufferToFile {
        if ($captureContent -and $contentBuffer.Count -gt 0) {
            $outputFileName = "${projectTaskNode}_${serviceNameNode}.env".ToLower()
            $outputPath = Join-Path $outputDirectory $outputFileName
            $contentBuffer | Out-File -FilePath $outputPath -Encoding utf8
            $contentBuffer.Clear()
        }
    }

    # Function to replace environment variable placeholders
    function Replace-EnvironmentVariables($value) {
        return [regex]::Replace($value, '%(\w+)%', {
            param($match)
            $envVar = $match.Groups[1].Value
            $envValue = [Environment]::GetEnvironmentVariable($envVar)
            if ($null -ne $envValue) {
                return $envValue
            }
            return $match.Value
        })
    }

    # Process each line in the YAML file
    foreach ($match in $nodeMatches) {
        $indent = $match.Groups[1].Value.Length / 2
        $nodeName = $match.Groups[2].Value
        $nodeValue = $match.Groups[3].Value.Trim()

        if ($indent -eq 0) {
            WriteBufferToFile
            $currentLevel = 0
            $nodePath = @($nodeName)
            $osduGroupNode = $nodeName
            
            $outputDirectory = "./src/$osduGroupNode".ToLower()
            New-Item -ItemType Directory -Force -Path $outputDirectory | Out-Null

            $captureContent = $false
        }
        elseif ($indent -gt $currentLevel) {
            if ($indent -eq 1) {
                $serviceNameNode = $nodeName
            }
            elseif ($indent -eq 2) {
                WriteBufferToFile
                $projectTaskNode = $nodeName
                $captureContent = $true
            }
            $currentLevel = $indent
            $nodePath += $nodeName
        }
        elseif ($indent -eq $currentLevel) {
            if ($indent -eq 1) {
                WriteBufferToFile
                $serviceNameNode = $nodeName
            }
            elseif ($indent -eq 2) {
                WriteBufferToFile
                $projectTaskNode = $nodeName
                $captureContent = $true
            }
            $nodePath[-1] = $nodeName
        }
        else {
            WriteBufferToFile
            $nodePath = $nodePath[0..$indent] + @($nodeName)
            $currentLevel = $indent
            if ($currentLevel -eq 1) {
                $serviceNameNode = $nodeName
            }
            elseif ($currentLevel -eq 2) {
                $projectTaskNode = $nodeName
                $captureContent = $true
            }
            else {
                $captureContent = $false
            }
        }

        # Capture content for child nodes of RUN and TEST (indent level 3)
        if ($captureContent -and $indent -eq 3) {
            if ($nodeValue -ne "") {
                $replacedValue = Replace-EnvironmentVariables $nodeValue
                $contentBuffer += "{0}={1}" -f $nodeName.ToUpper(), $replacedValue
            } else {
                $contentBuffer += "{0}=" -f $nodeName.ToUpper()
            }
        }
    }

    # Write the last file if there's content in the buffer
    WriteBufferToFile
}

function Get-AppInsights {
    Write-Host "`n=================================================================="
    Write-Host "Downloading Application Insights Agent"
    Write-Host "=================================================================="

    $url = "https://github.com/microsoft/ApplicationInsights-Java/releases/download/3.5.4/applicationinsights-agent-3.5.4.jar"
    $outputPath = "./src/applicationinsights-agent.jar"

    try {
        Invoke-WebRequest -Uri $url -OutFile $outputPath
        Write-Host "Application Insights agent downloaded successfully to $outputPath"
    } catch {
        Write-Host "Error downloading Application Insights agent: $_"
        exit 1
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
Get-AppInsights
New-EnvFile
New-ServiceEnvFile
# New-YamlFile
New-VSCodeSettings