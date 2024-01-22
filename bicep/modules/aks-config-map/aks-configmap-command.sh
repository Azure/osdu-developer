
set -e +H
# -e to exit on error
# +H to prevent history expansion

# This script is used to apply a ConfigMap to an AKS cluster using the az aks command invoke command.

if [ "$initialDelay" != "0" ]
then
    echo "Waiting on RBAC replication ($initialDelay)"
    sleep $initialDelay

    #Force RBAC refresh
    az logout
    az login --identity
fi

# Function to convert semi-colon-separated key-value pairs in $dataPropertyLike to YAML format
convert_properties_to_yaml() {
    local IFS=";"
    for pair in $dataPropertyLike; do
        IFS='=' read -r key value <<< "$pair"
        echo "  $key: \"$value\""
    done
    echo "" # Add an empty line for separation
}

# Function to append file-like data in $dataFileLike to YAML format, converting \t to spaces
append_files_to_yaml() {
    local IFS=";"
    for file in $dataFileLike; do
        local name="${file%%: *}"
        local content="${file#*: |}"
        # Process content to ensure correct new line handling and indentation
        content=$(echo "$content" | sed 's/\\n/\n/g' | sed 's/^/    /') # Adjust for actual new lines and indent
        echo "  $name: |"
        echo "$content"
    done
}


echo "Checking and updating configmap $configMap in AKS Cluster $aksName in $RG"


# Combining property-like and file-like data into the ConfigMap
combinedYaml=$(cat <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: ${configMap}
  namespace: ${namespace}
data:
$(convert_properties_to_yaml)
$(append_files_to_yaml)
EOF
)

echo "Applying ConfigMap $configMap in AKS Cluster $aksName in $RG"
cmdOut=$(az aks command invoke -g $RG -n $aksName -o json --command "echo '$combinedYaml' | kubectl apply -f -")
echo $cmdOut


jsonOutputString=$cmdOut
echo $jsonOutputString > $AZ_SCRIPTS_OUTPUT_PATH
