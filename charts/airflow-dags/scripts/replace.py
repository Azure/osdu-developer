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
                    if '=' in line:
                        var_name, _ = line.split('=', 1)
                        
                        # Convert dictionary values
                        processed_dict = {}
                        for k, v in replace.items():
                            # Handle boolean values - keep them as lowercase strings
                            if isinstance(v, str):
                                if v.lower() == "true":
                                    processed_dict[k] = "true"
                                elif v.lower() == "false":
                                    processed_dict[k] = "false"
                                else:
                                    processed_dict[k] = v
                            else:
                                processed_dict[k] = str(v)
                        
                        # Format as Python code
                        replace_str = json.dumps(processed_dict, indent=2)
                        modified_line = f"{var_name.rstrip()} = {replace_str}"
                    else:
                        modified_line = line.replace(find, json.dumps(replace))
                else:
                    modified_line = line.replace(find, str(replace))
                break
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