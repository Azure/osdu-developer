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
  echo -e "Usage: $0 --subscription SUBSCRIPTION_ID\n"
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
      AZURE_SUBSCRIPTION=$OPTARG
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
if [[ -z "$AZURE_SUBSCRIPTION" ]];
then
    echo "Error: You must provide a SubscriptionId" >&2
    print_help
    exit 1
fi

# Check Azure CLI version.
REQUIRED_AZ_CLI_VERSION="2.58.0"
CURRENT_AZ_CLI_VERSION="$(az --version | head -n 1 | awk -F' ' '{print $2}')"

if [[ $(echo -e "$REQUIRED_AZ_CLI_VERSION\n$CURRENT_AZ_CLI_VERSION"|sort -V|head -n1) != $REQUIRED_AZ_CLI_VERSION ]]; then
  echo "This script requires Azure CLI version $REQUIRED_AZ_CLI_VERSION or higher. You have version $CURRENT_AZ_CLI_VERSION."
  exit 1
fi


###############################
# Gather Information
TENANT_ID=$(az account show --query tenantId -o tsv)
# Fetch Node Resource Group from AKS Cluster
node_resource_group=$(az aks show -g $AZURE_RESOURCE_GROUP -n $AKS_NAME --query nodeResourceGroup -o tsv)
if [[ -n "$INGRESS" && "$INGRESS" == 'internal' ]]; then
    WEB_ENDPOINT="https://$(az network lb frontend-ip list --lb-name kubernetes-internal -g "$node_resource_group" --query '[].privateIPAddress' -o tsv)"
else
    WEB_ENDPOINT="https://$(az network public-ip list -g "$node_resource_group" --query "[?contains(name, 'kubernetes')].ipAddress" -o tsv)"
fi

ACCESS_TOKEN=$(curl --request POST \
  --url https://login.microsoftonline.com/${TENANT_ID}/oauth2/v2.0/token \
  --header "content-type: application/x-www-form-urlencoded" \
  --data "grant_type=client_credentials" \
  --data "client_id=${AZURE_CLIENT_ID}" \
  --data "client_secret=${AZURE_CLIENT_SECRET}" \
  --data "scope=${AZURE_CLIENT_ID}/.default" |jq -r .access_token)

USER_ID=$(az ad signed-in-user show --query id -o tsv)


###############################
# Add the first user.
if [ -n "$ACCESS_TOKEN" ] && [ -n "$USER_ID" ]; then
    json_payload=$(jq -n --arg email "$USER_ID" '{"email": $email, "role": "MEMBER"}')

    # Add the first user.
    response=$(curl -s -w "%{http_code}" -X POST "${WEB_ENDPOINT}/api/entitlements/v2/groups/users@opendes.contoso.com/members" \
        -H "Authorization: Bearer ${ACCESS_TOKEN}" \
        -H "Accept: application/json" \
        -H "data-partition-id: opendes" \
        -H "Content-Type: application/json" \
        -d "$json_payload")

    # Extract HTTP status code from the last three characters
    http_status_code=$(echo "$response" | grep -oE '[0-9]{3}$')

    # Remove the last three characters (HTTP status code) to isolate the body
    body=${response%???}

    # Check the response code and act accordingly
    if [ "$http_status_code" -eq 200 ] || [ "$http_status_code" -eq 201 ] || [ "$http_status_code" -eq 409 ]; then
        echo "Request successful. Body: $body"
    else
        echo "Request failed with status $http_status_code. Body: $body"
    fi

    # Assign the Ops role to the user.
    response=$(curl -s -w "%{http_code}" -X POST "${WEB_ENDPOINT}/api/entitlements/v2/groups/users.datalake.ops@.opendes.contoso.com/members" \
      -H "accept: application/json" \
      -H "content-type: application/json" \
      -H "authorization: Bearer ${ACCESS_TOKEN}" \
      -H "data-partition-id: opendes" \
      -d "$json_payload")
      
    # Extract HTTP status code from the last three characters
    http_status_code=$(echo "$response" | grep -oE '[0-9]{3}$')

    # Remove the last three characters (HTTP status code) to isolate the body
    body=${response%???}

    # Check the response code and act accordingly
    if [ "$http_status_code" -eq 200 ] || [ "$http_status_code" -eq 201 ] || [ "$http_status_code" -eq 409 ]; then
        echo "Request successful. Body: $body"
    else
        echo "Request failed with status $http_status_code. Body: $body"
    fi
    
else
    if [ -z "$ACCESS_TOKEN" ]; then echo "Failed to retrieve access token."; fi
    if [ -z "$USER_ID" ]; then echo "Failed to retrieve user ID."; fi
    exit 1
fi


###############################
# Get Refresh Token using Authorization Code
if [[ -n $AUTH_CODE ]]; then
    echo "Getting a Refresh Token using the Authorization Code..."
    
    response=$(curl -s -w "%{http_code}" --request POST \
      --url https://login.microsoftonline.com/${TENANT_ID}/oauth2/v2.0/token \
      --header "Content-Type: application/x-www-form-urlencoded" \
      --data-urlencode "grant_type=authorization_code" \
      --data-urlencode "redirect_uri=$WEB_ENDPOINT/auth/" \
      --data-urlencode "client_id=$AZURE_CLIENT_ID" \
      --data-urlencode "client_secret=$AZURE_CLIENT_SECRET" \
      --data-urlencode "scope=$AZURE_CLIENT_ID/.default openid profile offline_access" \
      --data-urlencode "code=$AUTH_CODE")

    # Extract HTTP status code from the last three characters
    http_status_code=$(echo "$response" | grep -oE '[0-9]{3}$')

    # Remove the last three characters (HTTP status code) to isolate the body
    body=${response%???}

    # Extract the Refresh Token from the body and set it as an environment variable
    refresh_token=$(echo "$body" | jq -r '.refresh_token')
    if [[ -n $refresh_token ]]; then
        azd env set AUTH_REFRESH $refresh_token
    fi

    # Clear the AUTH_CODE
    azd env set AUTH_CODE ""
fi

