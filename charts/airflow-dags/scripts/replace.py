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
            if not isinstance(item, dict) or 'find' not in item or 'replace' not in item:
                continue  # Skip invalid items
                
            find = item['find']
            replace = item['replace']
            
            if find in line:
                if isinstance(replace, (dict, list)):
                    if '=' in line:
                        var_name, _ = line.split('=', 1)
                        
                        # Convert dictionary values
                        processed_dict = {}
                        for k, v in replace.items():
                            # Handle template variables
                            if isinstance(v, str) and '{{' in v:
                                processed_dict[k] = v  # Keep template syntax intact
                            # Handle boolean values
                            elif isinstance(v, str) and v.lower() in ['true', 'false']:
                                processed_dict[k] = v.lower()
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
    raw_json = os.environ['SEARCH_AND_REPLACE']
    
    try:
        replacements = json.loads(raw_json)
        with open(input_file, 'r') as f:
            content = f.read()

        processed_content = process_replacements(content, replacements)

        with open(output_file, 'w') as f:
            f.write(processed_content)
            
    except Exception as e:
        print(f"ERROR: An unexpected error occurred: {str(e)}")
        sys.exit(1)

if __name__ == '__main__':
    main()