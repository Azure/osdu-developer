#!/bin/bash

###############################################################################################
#  ----------------------------                                                               #
#  preDeploy - Pre Deploy                                                                     #
#  ----------------------------                                                               #
#                                                                                             #
# Usage: ./hook-predeploy.sh <options>                                                        #            
#                                                                                             #
# Prerequisites:                                                                              #
#   1. Ensure you have Azure CLI installed, and you're logged in to Azure CLI.                #
#                                                                                             #
# Options:                                                                                    # 
#   -s : Specify a particular subscriptionId to use.                                          #
#   -h : Print help message and exit                                                          #
#                                                                                             #
# Note:                                                                                       #
#   You must provide a subscription ID                                                        #
#                                                                                             #
###############################################################################################

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
PARENT_DIR=`dirname $SCRIPT_DIR`
ROOT_DIR=`dirname $PARENT_DIR`

if [[ $SCRIPT_DIR == "/usr/local/bin" ]]
then
    ROOT_DIR="/workspace"
else
    ROOT_DIR=`dirname $PARENT_DIR`
fi

print_help() {
  echo -e "Usage: $0 -s SUBSCRIPTION_ID\n"
  echo -e "Options:"
  echo -e " -s Set the subscription ID"
  echo -e " -h Print this help message and exit"
  echo -e "\nYou must provide a SubscriptionId."
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
      AZURE_SUBSCRIPTION_ID=$OPTARG
      ;;
    \? )
      echo "Invalid option: -$OPTARG" >&2
      print_help
      exit 1
      ;;
    : )
      echo "Option -$OPTARG requires an argument." >&2
      print_help
      exit 1
      ;;
  esac
done
shift $((OPTIND -1))

###############################
# Checks
if [[ -z "$AZURE_SUBSCRIPTION_ID" ]];
then
    echo "Error: You must provide a SubscriptionId" >&2
    print_help
    exit 1
fi

if [ -z $AZURE_CLIENT_ID ]; then
  echo 'ERROR: AZURE_CLIENT_ID not provided'
  exit 1;
fi

if [ -z $AZURE_CLIENT_SECRET ]; then
  echo 'ERROR: AZURE_CLIENT_ID not provided'
  exit 1;
fi

if [ -z $AZURE_RESOURCE_GROUP ]; then
  echo 'ERROR: AZURE_RESOURCE_GROUP not provided'
  exit 1;
fi

if [ -z $AKS_NAME ]; then
  echo 'ERROR: AKS_NAME not provided'
  exit 1;
fi


if [[ ! -n $AZURE_TENANT_ID ]]; then
  AZURE_TENANT_ID=$(az account show --query tenantId -o tsv | tr -d '\r')
  azd env set AZURE_TENANT_ID $AZURE_TENANT_ID
fi

###############################
# Add Ingress
if [[ ! -n $AUTH_INGRESS ]]; then
  echo "Fetching Ingress IP Address..."

  # Fetch Node Resource Group from AKS Cluster
  node_group=$(az aks show -g $AZURE_RESOURCE_GROUP -n $AKS_NAME --query nodeResourceGroup -o tsv)
  if [[ -n "$INGRESS" && "$INGRESS" == 'internal' ]]; then
      AUTH_INGRESS="$(az network lb frontend-ip list --lb-name kubernetes-internal -g "$node_group" --query '[].privateIPAddress' -o tsv | tr -d '\r')"
  else
      AUTH_INGRESS="$(az network public-ip list -g "$node_group" --query "[?contains(name, 'kubernetes')].ipAddress" -o tsv | tr -d '\r')"
  fi

  azd env set AUTH_INGRESS $AUTH_INGRESS
fi


###############################
# Get Refresh Token using Authorization Code
if [[ -z "$AUTH_REFRESH" ]]; then
    if [[ -z "$AUTH_CODE" ]]; then
        echo "Error: Neither AUTH_CODE nor AUTH_REFRESH is available."
        exit 1
    else
        echo "Getting a Refresh Token using the Authorization Code..."
        
        response=$(curl -s -w "%{http_code}" --request POST \
          --url https://login.microsoftonline.com/${AZURE_TENANT_ID}/oauth2/v2.0/token \
          --header "Content-Type: application/x-www-form-urlencoded" \
          --data-urlencode "grant_type=authorization_code" \
          --data-urlencode "redirect_uri=https://$AUTH_INGRESS/auth/" \
          --data-urlencode "client_id=$AZURE_CLIENT_ID" \
          --data-urlencode "client_secret=$AZURE_CLIENT_SECRET" \
          --data-urlencode "scope=$AZURE_CLIENT_ID/.default openid profile offline_access" \
          --data-urlencode "code=$AUTH_CODE")

        # Extract HTTP status code from the last three characters
        http_status_code=$(echo "$response" | grep -oE '[0-9]{3}$')

        # Remove the last three characters (HTTP status code) to isolate the body
        body=${response%???}

        # Check the response code and act accordingly
        if [ "$http_status_code" -eq 200 ]; then
            echo "Request successful."
            # Set the refresh token and void the auth code.
            refresh_token=$(echo "$body" | jq -r '.refresh_token')
            azd env set AUTH_REFRESH $refresh_token
            azd env set AUTH_CODE ""
        else
            echo "Request failed with status $http_status_code. Body: $body"
            exit 1
        fi
    fi
fi

output=$(azd env get-values)
AZURE_RESOURCE_GROUP=$(echo "$output" | grep "AZURE_RESOURCE_GROUP" | cut -d'=' -f2 | tr -d '"')
AZURE_TENANT_ID=$(echo "$output" | grep "AZURE_TENANT_ID" | cut -d'=' -f2 | tr -d '"')
AZURE_CLIENT_ID=$(echo "$output" | grep "AZURE_CLIENT_ID" | cut -d'=' -f2 | tr -d '"')
AZURE_CLIENT_SECRET=$(echo "$output" | grep "AZURE_CLIENT_SECRET" | cut -d'=' -f2 | tr -d '"')
AUTH_INGRESS=$(echo "$output" | grep "AUTH_INGRESS" | cut -d'=' -f2 | tr -d '"')
AUTH_REFRESH=$(echo "$output" | grep "AUTH_REFRESH" | cut -d'=' -f2 | tr -d '"')

mkdir -p .vscode
cat << EOF > ".vscode/settings.json"
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
EOF

