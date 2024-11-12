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

# Ensure necessary packages are installed
apk add --no-cache curl zip jq

echo "Waiting on Identity RBAC replication (${initialDelay})"
sleep "${initialDelay}"

echo "###########################"
echo "${SEARCH_AND_REPLACE}"
echo "###########################"

# Download the source code and extract it.
url_basename=$(basename "${URL}")
echo "Derived filename from URL: ${url_basename}"
echo "Downloading file from ${URL} to ${url_basename}"
curl -so "${url_basename}" "${URL}"
echo "Extracting tar.gz archive..."
mkdir -p extracted_files
tar -xzf "${url_basename}" --strip-components=1 -C extracted_files

# Process the replacements
csv_file="extracted_files/${FILE}/csv_ingestion_all_steps.py"
output_file="extracted_files/${FILE}/csv-parser.py"

if [ -f "${csv_file}" ]; then
    echo "Processing ${csv_file} file"

    # Number of replacements
    num_replacements=$(echo "${SEARCH_AND_REPLACE}" | jq '. | length')

    # Initialize arrays
    declare -a finds
    declare -a replaces
    declare -a replace_types

    # Build arrays
    for (( idx=0; idx<${num_replacements}; idx++ )); do
        finds[$idx]=$(echo "${SEARCH_AND_REPLACE}" | jq -r ".[$idx].find")
        replace_type=$(echo "${SEARCH_AND_REPLACE}" | jq -r ".[$idx].replace | type")
        replace_types[$idx]=$replace_type
        if [ "$replace_type" == "string" ]; then
            replaces[$idx]=$(echo "${SEARCH_AND_REPLACE}" | jq -r ".[$idx].replace")
        else
            replaces[$idx]=$(echo "${SEARCH_AND_REPLACE}" | jq -c ".[$idx].replace")
        fi
    done

    # Empty the output file
    > "$output_file"

    # Read the input file line by line
    while IFS= read -r line || [[ -n "$line" ]]; do
        replaced=0
        # For each 'find'/'replace' pair
        for idx in "${!finds[@]}"; do
            find_placeholder="${finds[$idx]}"
            replace_value="${replaces[$idx]}"
            replace_type="${replace_types[$idx]}"

            if [[ "$line" == *"$find_placeholder"* ]]; then
                # Line contains the placeholder

                if [ "$replace_type" == "object" ]; then
                    # 'replace_value' is a JSON object

                    # Split the line at the placeholder
                    line_before_placeholder="${line%%$find_placeholder*}"
                    line_after_placeholder="${line#*$find_placeholder}"

                    # Get the indentation of the line up to the placeholder
                    leading_spaces=$(echo "$line_before_placeholder" | sed -n 's/^\(\s*\).*$/\1/p')

                    # Format the JSON with jq
                    formatted_json=$(echo "$replace_value" | jq '.')

                    # Indent the JSON
                    indented_json=$(echo "$formatted_json" | sed "s/^/${leading_spaces}/")

                    # Output the line before the placeholder (excluding placeholder)
                    echo -n "$line_before_placeholder" >> "$output_file"

                    # Output the indented JSON
                    echo "$indented_json" >> "$output_file"

                    # Output the rest of the line after the placeholder, if any
                    if [ -n "$line_after_placeholder" ]; then
                        echo "$line_after_placeholder" >> "$output_file"
                    fi
                else
                    # 'replace_value' is a string

                    # Replace the placeholder in the line
                    replaced_line="${line//$find_placeholder/$replace_value}"

                    # Output the modified line
                    echo "$replaced_line" >> "$output_file"
                fi
                replaced=1
                break  # Skip checking other placeholders for this line
            fi
        done
        if [[ $replaced -eq 0 ]]; then
            # Line did not contain any placeholder
            echo "$line" >> "$output_file"
        fi
    done < "$csv_file"

    # Remove the original file
    rm "$csv_file"
fi

# Compress the DAG folder and upload it to a file share.
rm "${url_basename}"
zip_filename="${url_basename%.tar.gz}.zip"
current_dir=$(pwd)
cd "extracted_files/${FILE}" || exit 1
zip -r "${current_dir}/${zip_filename}" .
cd - || exit 1

az storage file upload -s "${SHARE}" --source "${zip_filename}" --enable-file-backup-request-intent --auth-mode login -onone
echo "Zip file ${zip_filename} uploaded to file share ${SHARE}."