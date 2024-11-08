#!/usr/bin/env python3

import json
import sys
import os
from typing import Dict, Any

def process_replacements(content: str, replacements: Dict[str, Any]) -> str:
    """Process the file content with the given replacements."""
    result = []
    for line in content.splitlines():
        modified_line = line
        for item in replacements:
            find = item['find']
            replace = item['replace']
            
            if find in line:
                if isinstance(replace, (dict, list)):
                    # Handle Python dictionary/list assignments
                    if '=' in line:
                        var_name, _ = line.split('=', 1)
                        # Format the dictionary assignment properly
                        replace_str = json.dumps(replace, indent=2)
                        replace_str = replace_str.replace('true', 'True').replace('false', 'False')
                        # Ensure proper Python dictionary formatting
                        modified_line = f"{var_name.rstrip()} = {replace_str}"
                    else:
                        # Handle non-assignment JSON
                        modified_line = line.replace(find, json.dumps(replace))
                else:
                    # Simple string replacement
                    modified_line = line.replace(find, str(replace))
                break
        # Only append non-empty lines
        if modified_line.strip():
            result.append(modified_line)
    return '\n'.join(result)

def main():
    input_file = os.environ['INPUT_FILE']
    output_file = os.environ['OUTPUT_FILE']
    replacements = json.loads(os.environ['SEARCH_AND_REPLACE'])

    with open(input_file, 'r') as f:
        content = f.read()

    processed_content = process_replacements(content, replacements)

    with open(output_file, 'w') as f:
        f.write(processed_content)

if __name__ == '__main__':
    main()