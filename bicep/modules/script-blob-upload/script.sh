#!/bin/bash
set -e

echo "Waiting on Identity RBAC replication ($initialDelay)"
sleep $initialDelay

# Installing curl
apk add --no-cache curl

echo "$CONTENT" > ${FILE_NAME}

# Upload the blob, overwriting if it exists
az storage blob upload -f ${FILE_NAME} -c ${CONTAINER} -n ${FILE_NAME} --overwrite
echo "Blob ${CONTAINER} uploaded to container ${CONTAINER}, overwriting if it existed."