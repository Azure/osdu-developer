#!/bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
PARENT_DIR=`dirname $SCRIPT_DIR`

AZURE_LOCATION="southcentralus"

WHAT_IF=1
VALIDATE_TEMPLATE=1

# ARM template and parameters file
TEMPLATE="$SCRIPT_DIR/main.test.bicep"
PARAMETERS="$SCRIPT_DIR/parameters.json"

# Retrieve Resource Group Name
if [ -z $RESOURCE_GROUP_NAME ]; then
  RESOURCE_GROUP_NAME="bicep-module-testing"
fi



# Check if Azure CLI Logged in, if not prompt to login then set default values.
AZURE_ACCOUNT=$(az account show --query '[tenantId, id, user.name]' -otsv)
if [ -z "$AZURE_ACCOUNT" ]; then
  az login --only-show-errors -o none
  AZURE_ACCOUNT=$(az account show --query '[tenantId, id, user.name]' -otsv 2>/dev/null)
fi
TENANT_ID=$(echo $AZURE_ACCOUNT |awk '{print $1}')
AZURE_USER=$(echo $AZURE_ACCOUNT |awk '{print $3}')
AZURE_USER_ID=$(az ad signed-in-user show --query id -o tsv)
AZURE_SIBLING_LOCATION=$(az account list-locations --query "[?name == '${AZURE_LOCATION}'].metadata.pairedRegion[0].name" -otsv)


###############################
## FUNCTIONS                 ##
###############################


function PrintMessage(){
  # Required Argument $1 = Message
  if [ ! -z "$1" ]; then
    echo "    $1"
  fi
}

function Verify(){
    # Required Argument $1 = Value to check
    # Required Argument $2 = Value description for error

    if [ -z "$1" ]; then
      echo "$2 is required and was not provided"
      exit 1
    fi
}

function CreateResourceGroup() {
  # Required Argument $1 = RESOURCE_GROUP
  # Required Argument $2 = LOCATION

  Verify $1 'CreateResourceGroup-ERROR: Argument (RESOURCE_GROUP) not received'
  Verify $2 'CreateResourceGroup-ERROR: Argument (LOCATION) not received'
  Verify $3 'CreateResourceGroup-ERROR: Argument (SIBLING LOCATION) not received'

  local _result=$(az group show --name $1 2>/dev/null)
  if [ "$_result"  == "" ]
    then
      az group create --name $1 \
        --location $2 \
        --tags CONTACT=$AZURE_USER SIBLING_REGION=$3 \
        -o none
      PrintMessage "  Resource Group Created."
    else
      PrintMessage "  Resource Group: $1 --> Already exists."
    fi
}


###############################
## Execution                 ##
###############################

printf "\n"
echo "=================================================================="
echo "Template Validation"
echo "=================================================================="

PrintMessage "Create Resource Group: $RESOURCE_GROUP_NAME"
CreateResourceGroup $RESOURCE_GROUP_NAME $AZURE_LOCATION $AZURE_SIBLING_LOCATION


# Validate the ARM template
if [[ $VALIDATE_TEMPLATE == 1 ]]; then
  if [[ $WHAT_IF == 1 ]]; then
    # Execute a deployment What-If operation at resource group scope.
    echo "Previewing changes deployed by [$TEMPLATE] ARM template..."
    az deployment group what-if --template-file $TEMPLATE \
      --resource-group $RESOURCE_GROUP_NAME \
      --parameter $PARAMETERS \
      -ojson

    if [[ $? == 0 ]]; then
      echo "[$TEMPLATE] ARM template validation succeeded"
    else
      echo "Failed to validate [$TEMPLATE] ARM template"
      exit
    fi
  else
    # Validate the ARM template
    echo "Validating [$TEMPLATE] ARM template..."
    az deployment group validate --template-file $TEMPLATE \
      --resource-group $RESOURCE_GROUP_NAME \
      --parameter $PARAMETERS \
      -ojson

    if [[ $? == 0 ]]; then
      echo "[$TEMPLATE] ARM template validation succeeded"
    else
      echo "Failed to validate [$TEMPLATE] ARM template"
      exit
    fi
  fi
fi

# Deploy the ARM template
echo "Deploying [$TEMPLATE] ARM template..."
az deployment group create --template-file $TEMPLATE \
      --resource-group $RESOURCE_GROUP_NAME \
      --parameter $PARAMETERS \
      -ojson 1>/dev/null

if [[ $? == 0 ]]; then
  echo "[$TEMPLATE] ARM template successfully provisioned"
else
  echo "Failed to provision the [$TEMPLATE] ARM template"
  exit
fi