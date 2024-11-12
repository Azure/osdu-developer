#!/bin/bash

set -e

# Install required packages
tdnf install -y tar curl zip

# Create and use working directory
WORK_DIR="/tmp/csvdag"
mkdir -p "${WORK_DIR}"
cd "${WORK_DIR}"

# Download and extract
url_basename=$(basename "${URL}")
echo "Downloading file from ${URL}"
curl --insecure -so "${url_basename}" "${URL}"

mkdir -p extracted_files
tar -xzf "${url_basename}" --strip-components=1 -C extracted_files

# Set up file paths for Python script
export INPUT_FILE="extracted_files/${FILE}/csv_ingestion_all_steps.py"
export OUTPUT_FILE="extracted_files/${FILE}/csv-parser.py"

# Run the Python replacement script
python3 /scripts/replace.py

# Remove the template file
rm "${INPUT_FILE}"

# Clean up and zip
rm "${url_basename}"
zip_filename="${url_basename%.tar.gz}.zip"
cd "extracted_files/${FILE}"
zip -r "${WORK_DIR}/${zip_filename}" .

# Copy to shared volume
cp "${WORK_DIR}/${zip_filename}" /share/
echo "Zip file ${zip_filename} copied to shared volume."