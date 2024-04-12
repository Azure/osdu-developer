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
# Require Common Functions
if [[ -f "$SCRIPT_DIR/functions.sh" ]]; then 
    source "$SCRIPT_DIR/functions.sh" 
fi

env