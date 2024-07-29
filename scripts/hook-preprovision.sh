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

###############################
# Common Functions
PrintMessage(){
  # Required Argument $1 = Message

  # +---------+---------+
  # |  Color  |  Value  |
  # +---------+---------+
  # |  black  |    0    |
  # |   red   |    1    |
  # |  green  |    2    |
  # | yellow  |    3    |
  # |  blue   |    4    |
  # | magenta |    5    |
  # |  cyan   |    6    |
  # |  white  |    7    |

  local _color="${2:-2}"

  if [[ ! -z "$1" ]]; then
    if [[ -t 1 ]]; then  # Check if stdout is a tty
      tput setaf $_color; echo "    $1" ; tput sgr0
    else
      echo "    $1"
    fi
  fi
}

###############################
# Version Check
REQUIRED_AZ_CLI_VERSION="2.62.0"
CURRENT_AZ_CLI_VERSION="$(az --version | head -n 1 | awk -F' ' '{print $2}')"

printf "\n"
PrintMessage "==================================================================" 4
PrintMessage "Azure CLI Version: ${CURRENT_AZ_CLI_VERSION}" 4
PrintMessage "==================================================================" 4

if [[ $(echo -e "$REQUIRED_AZ_CLI_VERSION\n$CURRENT_AZ_CLI_VERSION" | sort -V | head -n1) != $REQUIRED_AZ_CLI_VERSION ]]; then
  echo "This script requires Azure CLI version $REQUIRED_AZ_CLI_VERSION or higher. You have version $CURRENT_AZ_CLI_VERSION."
  exit 1
fi


###############################
# Extension Check
required_extensions=("k8s-configuration")
printf "\n"
PrintMessage "==================================================================" 4
PrintMessage "Azure CLI Extensions: ${required_extensions[*]}" 4
PrintMessage "==================================================================" 4

for extension in "${required_extensions[@]}"; do
    az_version_output=$(az version --output json)
    
    if echo "$az_version_output" | jq -e ".extensions.\"$extension\"" > /dev/null; then
        echo "  Found [$extension] extension. Updating..."
        az extension update --name "$extension" --allow-preview true --only-show-errors
    else
        echo "  Not Found [$extension] extension. Installing..."
        az extension add --name "$extension" --allow-preview true --only-show-errors

        if [ $? -eq 0 ]; then
            echo "  [$extension] extension successfully installed"
        else
            echo "  Failed to install [$extension] extension"
            exit 1
        fi
    fi
done


###############################
# Login Check
account_info=$(az account show -o json 2>/dev/null)
if [[ -n "$account_info" ]]; then
    user_name=$(echo "$account_info" | jq -r '.user.name')
    printf "\n"
    PrintMessage "==================================================================" 4
    PrintMessage "Logged in as: $user_name" 4
    PrintMessage "==================================================================" 4
else
    printf "\n"
    PrintMessage "==================================================================" 4
    PrintMessage "Azure CLI Login Required" 1
    PrintMessage "      az login --scope https://graph.microsoft.com//.default" 1
    PrintMessage "==================================================================" 4

    echo "Failed to log in. Exiting."
    exit 1
fi

###############################
# Subscription Check
if [[ -z "$AZURE_SUBSCRIPTION_ID" ]]; then
    AZURE_SUBSCRIPTION_ID=$(az account show --query id -o tsv | tr -d '\r')
    printf "\n"
    PrintMessage "==================================================================" 4
    PrintMessage "Default Subscription: ${AZURE_SUBSCRIPTION_ID}" 4
    PrintMessage "==================================================================" 4
    azd env set AZURE_SUBSCRIPTION_ID $AZURE_SUBSCRIPTION_ID
fi

###############################
# Location Check
if [[ -z "$AZURE_LOCATION" ]]; then
    AZURE_LOCATION="eastus2"
    printf "\n"
    PrintMessage "==================================================================" 4
    PrintMessage "Default Location: $AZURE_LOCATION" 4
    PrintMessage "==================================================================" 4
    azd env set AZURE_LOCATION $AZURE_LOCATION
fi


###############################
# Application Check
if [[ -z $AZURE_CLIENT_ID ]]; then
  
  # Define the application name using the Azure subscription ID
  AZURE_CLIENT_NAME="osdu-${AZURE_ENV_NAME}-${AZURE_SUBSCRIPTION_ID}"

  # Display the created application information
  printf "\n"
  PrintMessage "==================================================================" 4
  PrintMessage "Creating Application: ${AZURE_CLIENT_NAME}" 4
  PrintMessage "==================================================================" 4

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
    "spa": {
        "redirectUris": ["https://localhost:8080/spa"],
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
  sleep 30

  # Retrieve the application ID using az ad app list
  AZURE_CLIENT_ID=$(az ad app list --display-name "$AZURE_CLIENT_NAME" --query "[0].appId" -o tsv | tr -d '\r')
  az ad sp create --id $AZURE_CLIENT_ID -o none
  
  PrintMessage "  Retrieving AZURE_CLIENT_ID.."
  azd env set AZURE_CLIENT_ID $AZURE_CLIENT_ID
fi


###############################
# Environment Variables
if [[ -z $AZURE_CLIENT_PRINCIPAL_OID ]]; then
  PrintMessage "  Retrieving AZURE_CLIENT_PRINCIPAL_OID..."
  azd env set AZURE_CLIENT_PRINCIPAL_OID $(az ad sp show --id $AZURE_CLIENT_ID --query "id" -otsv | tr -d '\r')
fi

if [[ -z $AZURE_CLIENT_SECRET ]]; then
  PrintMessage "  Retrieving AZURE_CLIENT_SECRET..."
  azd env set AZURE_CLIENT_SECRET $(az ad app credential reset --id $AZURE_CLIENT_ID --query password --only-show-errors -otsv | tr -d '\r')
fi

if [[ -z $EMAIL_ADDRESS ]]; then
  PrintMessage "  Retrieving User Email Address..."
  azd env set EMAIL_ADDRESS $(az ad signed-in-user show --query userPrincipalName -o tsv | tr -d '\r')
fi
