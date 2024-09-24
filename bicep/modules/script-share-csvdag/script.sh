#!/bin/bash
set -e

# This script performs the following tasks:
# 1. Waits for Identity RBAC replication.
# 2. Installs required packages.
# 3. Downloads a tar.gz file from a specified URL and extracts its contents.
# 4. Processes a specific Python file within the extracted contents, performing complex find/replace operations based on a provided JSON configuration.
# 5. Compresses the DAG and uploads it to a file share.
# 
# The pattern of the SEARCH_AND_REPLACE variable is as follows:
# [
#   {
#     "find": "{| DAG_NAME |}",
#     "replace": "csv-parser"
#   },
#   {
#     "find": "{| DOCKER_IMAGE |}",
#     "replace": "msosdu.azurecr.io/csv-parser-msi:v5"
#   }
# ]
# 
# The SEARCH_AND_REPLACE variable is required for the script to perform the find/replace operations.



echo "Waiting on Identity RBAC replication (${initialDelay})"
sleep "${initialDelay}"
apk add --no-cache curl zip

# Download the source code and extract it.
url_basename=$(basename ${URL})
echo "Derived filename from URL: ${url_basename}"
echo "Downloading file from ${URL} to ${url_basename}"
curl -so "${url_basename}" "${URL}"
echo "Extracting tar.gz archive..."
mkdir -p extracted_files
tar -xzf "${url_basename}" --strip-components=1 -C extracted_files


# Find and Replace.
csv_file="extracted_files/${FILE}/csv_ingestion_all_steps.py"
if [ -f "${csv_file}" ]; then
    echo "Processing ${csv_file} file"

    # Escape patterns for sed
    escape_sed_pattern() {
        printf '%s' "$1" | sed 's/[\/&]/\\&/g; s/[][$.*^]/\\&/g'
    }
    escape_sed_replacement() {
        printf '%s' "$1" | sed 's/[\/&]/\\&/g'
    }

    # Create sed script from search and replace JSON
    sed_script_file="sed_script.sed"

    echo "${SEARCH_AND_REPLACE}" | jq -c '.[]' | while IFS= read -r item; do
        find=$(echo "$item" | jq -r '.find')
        replace=$(echo "$item" | jq -r '.replace')

        find_escaped=$(escape_sed_pattern "$find")
        replace_escaped=$(escape_sed_replacement "$replace")

        echo "find: ${find_escaped}"
        echo "replace: ${replace_escaped}"

        echo "s/${find_escaped}/${replace_escaped}/g" >> "$sed_script_file"
    done

    echo "Running sed script:"
    cat "$sed_script_file"
    sed -f "$sed_script_file" "$csv_file" > "extracted_files/${FILE}/csv-parser.py"
    rm "$sed_script_file"
    rm "$csv_file"
fi

# Compress the DAG folder and upload it to a file share.
rm "${url_basename}"
zip_filename="${url_basename%.tar.gz}.zip"
current_dir=$(pwd)
cd "extracted_files/${FILE}" || exit 1
zip -r "${current_dir}/${zip_filename}" .
cd - || exit 1

az storage file upload -s "${SHARE}" --source "${zip_filename}" -onone
echo "Zip file ${zip_filename} uploaded to file share ${SHARE}."
