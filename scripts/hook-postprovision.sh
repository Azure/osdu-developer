#!/bin/bash

###############################################################################################
#  ----------------------------                                                               #
#  postProvision - Post Provision                                                               #
#  ----------------------------                                                               #
#                                                                                             #
# Usage: ./hook-postprovision.sh <options>                                                     #            
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
  exit 1;
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

if [ -z $AZURE_CLIENT_ID ]; then
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


###############################
# Checking Flux Compliance
echo "Checking Software Installation..."

# Initialize timer
end=$((SECONDS+1200))  # 1200 seconds = 20 minutes

# Loop to check Flux compliance every 30 seconds up to 10 minutes
while [ $SECONDS -lt $end ]; do
    
    compliance_state=$(az k8s-configuration flux show -t managedClusters -g $AZURE_RESOURCE_GROUP --cluster-name $AKS_NAME --name flux-system --query 'complianceState' -o tsv | tr -d '\r')
    
    echo "Current Software State: $compliance_state"

    if [ "$compliance_state" == "Compliant" ]; then
        echo "Software has been installed."
        break
    else
        echo "Software still installing, retrying in 30 seconds."
        sleep 30
    fi
done

if [ $SECONDS -ge $end ]; then
    echo "Software check timed out after 10 minutes."
fi


###############################
# Add Redirect URIs to Azure AD App
redirect_uris=()  # Initialize an empty array to hold the redirect URIs

# Fetch Node Resource Group from AKS Cluster
node_resource_group=$(az aks show -g $AZURE_RESOURCE_GROUP -n $AKS_NAME --query nodeResourceGroup -o tsv | tr -d '\r')

# Fetch Public IP Address of the Load Balancer named 'kubernetes'
public_ip=$(az network public-ip list -g "$node_resource_group" --query "[?contains(name, 'kubernetes')].ipAddress" -o tsv | tr -d '\r')
if [[ -n $public_ip ]]; then
    echo "Adding Public Web Endpoint: ${public_ip}"
    redirect_uris+=("https://$public_ip/auth/")  # Add public ingress URI
fi
azd env set INGRESS_EXTERNAL https://$public_ip/auth/

# Fetch Private IP Address from the Load Balancer named 'kubernetes-internal'
private_ip=$(az network lb frontend-ip list --lb-name kubernetes-internal -g "$node_resource_group" --query [].privateIPAddress -o tsv | tr -d '\r')
if [[ -n $private_ip ]]; then
    echo "Adding Private Web Endpoint: ${private_ip}"
    redirect_uris+=("https://$private_ip/auth/")  # Add private ingress URI
fi
azd env set INGRESS_INTERNAL https://$private_ip/auth/

_oid=$(az ad app show --id $AZURE_CLIENT_ID --query id -o tsv | tr -d '\r')

# Update Azure AD app only if there are URIs to add
if [ ${#redirect_uris[@]} -gt 0 ]; then
    echo "=================================================================="
    echo "Adding Redirect URIs: ${redirect_uris[@]}"
    echo "=================================================================="
    
    # Prepare web and SPA redirect URIs JSON payload
    REDIRECT_URIS=$(printf '"%s",' "${redirect_uris[@]}")
    REDIRECT_URIS="${REDIRECT_URIS%,}" # Remove trailing comma

    SHA_REDIRECT_URIS=$(printf '"%sspa/",' "${redirect_uris[@]}")
    SHA_REDIRECT_URIS="${SHA_REDIRECT_URIS%,}" # Remove trailing comma

    # Correctly format the JSON payload
    JSON_PAYLOAD=$(cat <<EOF
{
    "web": {
        "redirectUris": [${REDIRECT_URIS}],
        "implicitGrantSettings": {
            "enableAccessTokenIssuance": false,
            "enableIdTokenIssuance": false
        }
    },
    "spa": {
        "redirectUris": [${SHA_REDIRECT_URIS}],
    }
}
EOF
)

    # Update web and SPA redirect URIs with implicitGrantSettings
    az rest \
      --method "PATCH" \
      --uri "https://graph.microsoft.com/v1.0/applications/${_oid}" \
      --headers "Content-Type=application/json" \
      --body "$JSON_PAYLOAD"
fi

sleep 30
open "$(azd env get-values | grep INGRESS_EXTERNAL | cut -d'=' -f2 | tr -d ' ')"