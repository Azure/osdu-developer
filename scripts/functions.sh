###############################
## FUNCTIONS                 ##
###############################

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

function Verify(){
    # Required Argument $1 = Value to check
    # Required Argument $2 = Value description for error

    if [[ -z $1 ]]; then
      echo "$2 is required and was not provided"
      exit 1
    fi
}

function SetAzureContext()
{
    # Required Argument $1 = SUBSCRIPTION
    Verify $1 'SetAzureContext-ERROR: Argument (SUBSCRIPTION) not received'

    local _subscription=$1

    az account set --subscription $1
    PrintMessage "Account Set: $(az account show --query name -o tsv)"
}

function CreateResourceGroup() {
  # Required Argument $1 = RESOURCE_GROUP
  # Required Argument $2 = LOCATION

  Verify $1 'CreateResourceGroup-ERROR: Argument (RESOURCE_GROUP) not received'
  Verify $2 'CreateResourceGroup-ERROR: Argument (LOCATION) not received'

  local _result=$(az group show --name $1 2>/dev/null)
  if [[ "$_result" == "" ]]; then
    az group create --name $1 \
      --location $2 \
      --tags CONTACT=$AZURE_USER VERSION=$VERSION REPO_PATH=$REPO_PATH \
      -o none
    PrintMessage "  Resource Group Created."
  else
    az tag update --resource-id /subscriptions/$CP_SUBSCRIPTION_ID/resourcegroups/$1 \
      --operation replace \
      --tags CONTACT=$AZURE_USER VERSION=$VERSION REPO_PATH=$REPO_PATH \
      -o none
    PrintMessage "  Resource Group: $1 --> Already exists."
  fi
}
