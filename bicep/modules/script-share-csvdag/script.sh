#!/bin/bash
set -e

echo "Waiting on Identity RBAC replication (${initialDelay})"
sleep "${initialDelay}"

# Installing required packages
apk add --no-cache curl zip

# Download and extract the file
url_basename=$(basename "${URL}")
echo "Downloading and extracting file from ${URL}"
curl -sL "${URL}" | unzip -d extracted_files -

# Process csv-parser.py file if it exists
if [ -f "extracted_files/csv-parser.py" ]; then
    echo "Processing csv-parser.py file"
    sed -i \
        -e "s/__KEYVAULT_URI__/${KEYVAULT_URI}/g" \
        -e "s/__APPINSIGHTS_KEY__/${APPINSIGHTS_KEY}/g" \
        -e "s/__AZURE_ENABLE_MSI__/${AZURE_ENABLE_MSI}/g" \
        -e "s/__AZURE_TENANT_ID__/${AZURE_TENANT_ID}/g" \
        -e "s/__AZURE_CLIENT_ID__/${AZURE_CLIENT_ID}/g" \
        -e "s/__AZURE_CLIENT_SECRET__/${AZURE_CLIENT_SECRET}/g" \
        -e "s/__AAD_CLIENT_ID__/${AAD_CLIENT_ID}/g" \
        extracted_files/csv-parser.py
fi

# Create and upload zip file
echo "Creating zip of contents and uploading to file share ${SHARE}"
zip_filename="${url_basename%.tar.gz}.zip"
(cd extracted_files && zip -r "../${zip_filename}" .)
az storage file upload -s "${SHARE}" --source "./${zip_filename}" -o none
echo "Zip file ${zip_filename} uploaded to file share ${SHARE}."

