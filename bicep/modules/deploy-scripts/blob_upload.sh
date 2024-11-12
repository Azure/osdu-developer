#!/bin/bash
set -e

# Installing curl
apk add --no-cache curl

echo "$CONTENT" > ${FILE_NAME}

# Upload the blob, overwriting if it exists
az login --identity
az storage blob upload -f ${FILE_NAME} -c ${CONTAINER} -n ${FILE_NAME} --overwrite --auth-mode login
echo "Blob ${CONTAINER} uploaded to container ${CONTAINER}, overwriting if it existed."