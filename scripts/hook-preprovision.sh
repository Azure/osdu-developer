#!/bin/bash

###############################################################################################
#  ----------------------------                                                               #
#  preProvision - Pre Provision                                                               #
#  ----------------------------                                                               #
#                                                                                             #
# Usage: ./hook-preprovision.sh <options>                                                     #            
#                                                                                             #
# Prerequisites:                                                                              #
#   1. Ensure you have Azure CLI installed, and you're logged in to Azure CLI.                #
#                                                                                             #
# Options:                                                                                    # 
#   -s : Specify a particular subscriptionId to use. If not provided, uses the current subscription.
#   -h : Print help message and exit                                                          #
#                                                                                             #
###############################################################################################

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
PARENT_DIR=$(dirname $SCRIPT_DIR)
ROOT_DIR=$(dirname $PARENT_DIR)

if [[ $SCRIPT_DIR == "/usr/local/bin" ]]
then
    ROOT_DIR="/workspace"
else
    ROOT_DIR=$(dirname $PARENT_DIR)
fi

print_help() {
  echo -e "Usage: $0 [-s SUBSCRIPTION_ID]\n"
  echo -e "Options:"
  echo -e " -s : Optionally specify a subscription ID to use. If not provided, the current subscription is used."
  echo -e " -h : Print this help message and exit"
}

# Parsing command-line arguments
AZURE_SUBSCRIPTION=""
while getopts ":hs:" opt; do
  case ${opt} in
    h )
      print_help
      exit 0
      ;;
    s )
      AZURE_SUBSCRIPTION=${OPTARG:-default_value}  # Set to a default value or leave as empty
      ;;
    \? )
      echo "Invalid option: -$OPTARG" >&2
      print_help
      exit 1
      ;;
    : )
      if [ "$OPTARG" != "s" ]; then
        echo "Option -$OPTARG requires an argument." >&2
        print_help
        exit 1
      fi
      ;;
  esac
done
shift $((OPTIND -1))


# Check Azure CLI version.
REQUIRED_AZ_CLI_VERSION="2.59.0"
CURRENT_AZ_CLI_VERSION="$(az --version | head -n 1 | awk -F' ' '{print $2}')"

if [[ $(echo -e "$REQUIRED_AZ_CLI_VERSION\n$CURRENT_AZ_CLI_VERSION"|sort -V|head -n1) != $REQUIRED_AZ_CLI_VERSION ]]; then
  echo "This script requires Azure CLI version $REQUIRED_AZ_CLI_VERSION or higher. You have version $CURRENT_AZ_CLI_VERSION."
  exit 1
fi

###############################
# Require Common Functions
if [[ -f "$SCRIPT_DIR/functions.sh" ]]; then 
    source "$SCRIPT_DIR/functions.sh" 
fi


###############################
# Subscription Check
if [[ -z "$AZURE_SUBSCRIPTION_ID" ]]; then
    AZURE_SUBSCRIPTION_ID=$(az account show --query id -o tsv)
    printf "\n"
    PrintMessage "==================================================================" 4
    PrintMessage "Default Subscription: ${AZURE_SUBSCRIPTION_ID}" 4
    PrintMessage "==================================================================" 4
    azd env set AZURE_SUBSCRIPTION_ID $AZURE_SUBSCRIPTION_ID
fi

###############################
## Feature Check             ##
###############################
printf "\n"
PrintMessage "==================================================================" 4
PrintMessage "Ensuring Proper Features are enabled." 4
PrintMessage "==================================================================" 4

PrintMessage "  Checking [aks-preview] extension..."
az extension show --name aks-preview &>/dev/null

if [[ $? == 0 ]]; then
  PrintMessage "  Found and updating..."
  az extension update --name aks-preview &>/dev/null
else
  PrintMessage "  Not Found and installing..."

  # Install aks-preview extension
  az extension add --name aks-preview 1>/dev/null

  if [[ $? == 0 ]]; then
    PrintMessage "  [aks-preview] extension successfully installed"
  else
    PrintMessage "  Failed to install [aks-preview] extension"
    exit
  fi
fi

# Registering AKS feature extensions
aksExtensions=(
  "RunCommandPreview"
  "EnablePodIdentityPreview"
  "PodSubnetPreview"
  "EnableImageCleanerPreview"
  "AKS-AzureKeyVaultSecretsProvider"
)


ok=0
registeringExtensions=()
for aksExtension in ${aksExtensions[@]}; do
  
  PrintMessage "  Checking if [$aksExtension] extension is already registered..."
  extension=$(az feature list -o table --query "[?contains(name, 'Microsoft.ContainerService/$aksExtension') && @.properties.state == 'Registered'].{Name:name}" --output tsv)

  if [[ -z $extension ]]; then
    PrintMessage "  [$aksExtension] extension is not registered."
    PrintMessage "  Registering [$aksExtension] extension..."

    az feature register --name $aksExtension --namespace Microsoft.ContainerService
    registeringExtensions+=("$aksExtension")
    ok=1
  else
    PrintMessage "  [$aksExtension] extension is already registered."
  fi
done


PrintMessage $registeringExtensions
delay=1

for aksExtension in ${registeringExtensions[@]}; do
  PrintMessage "  Checking if [$aksExtension] extension is already registered..."

  while true; do
    extension=$(az feature list -o table --query "[?contains(name, 'Microsoft.ContainerService/$aksExtension') && @.properties.state == 'Registered'].{Name:name}" --output tsv)
    if [[ -z $extension ]]; then
      echo -n "."
      sleep $delay
    else
      echo "."
      break
    fi
  done
done

if [[ $ok == 1 ]]; then
  PrintMessage "  Refreshing the registration of the Microsoft.ContainerService resource provider..."
  az provider register --namespace Microsoft.ContainerService
  PrintMessage "  Microsoft.ContainerService resource provider registration successfully refreshed"
fi

if [[ -z $AZURE_CLIENT_ID ]]; then
  
  # Define the application name using the Azure subscription ID
  AZURE_CLIENT_NAME="osdu-${AZURE_ENV_NAME}-${AZURE_SUBSCRIPTION_ID}"

  # Display the created application information
  printf "\n"
  echo "=================================================================="
  echo " Creating Application: ${AZURE_CLIENT_NAME}"
  echo "=================================================================="

# Correctly format the JSON payload and headers
JSON_PAYLOAD=$(cat <<EOF
{
    "displayName": "${AZURE_CLIENT_NAME}",
    "signInAudience": "AzureADMyOrg",
    "web": {
        "redirectUris": ["https://localhost:8080/"],
        "implicitGrantSettings": {
            "enableIdTokenIssuance": true,
            "enableAccessTokenIssuance": true
        }
    },
    "requiredResourceAccess": [
        {
            "resourceAppId": "00000003-0000-0000-c000-000000000000",
            "resourceAccess": [
                {
                    "id": "e1fe6dd8-ba31-4d61-89e7-88639da4683d",
                    "type": "Scope"
                }
            ]
        }
    ]
}
EOF
)

  # Use az rest to create the application
  az rest --method POST \
          --uri "https://graph.microsoft.com/v1.0/applications" \
          --headers 'Content-Type=application/json' \
          --body "$JSON_PAYLOAD" > /dev/null 2>&1

  # Wait for the application to be fully created
  sleep 45

  # Retrieve the application ID using az ad app list
  AZURE_CLIENT_ID=$(az ad app list --display-name "$AZURE_CLIENT_NAME" --query "[0].appId" -o tsv)
  az ad sp create --id $AZURE_CLIENT_ID -o none
  
  PrintMessage "  Retrieving AZURE_CLIENT_ID.."
  azd env set AZURE_CLIENT_ID $AZURE_CLIENT_ID
fi


if [[ -z $AZURE_CLIENT_PRINCIPAL_OID ]]; then
  PrintMessage "  Retrieving AZURE_CLIENT_PRINCIPAL_OID..."
  azd env set AZURE_CLIENT_PRINCIPAL_OID $(az ad sp show --id $AZURE_CLIENT_ID --query "id" -otsv)
fi

if [[ -z $AZURE_CLIENT_SECRET ]]; then
  PrintMessage "  Retrieving AZURE_CLIENT_SECRET..."
  azd env set AZURE_CLIENT_SECRET $(az ad app credential reset --id $AZURE_CLIENT_ID --query password --only-show-errors -otsv)
fi
