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
                        # Format as Python literal with 2-space indentation
                        replace_str = json.dumps(replace, indent=2)
                        replace_str = replace_str.replace('true', 'False').replace('false', 'False')
                        # Remove any extra indentation from the JSON string
                        replace_lines = replace_str.splitlines()
                        if len(replace_lines) > 1:
                            # Keep first line as is
                            result_lines = [replace_lines[0]]
                            # Remove extra indentation from subsequent lines
                            base_indent = len(var_name.rstrip()) + 2  # account for "= "
                            for line in replace_lines[1:]:
                                result_lines.append(' ' * base_indent + line.lstrip())
                            replace_str = '\n'.join(result_lines)
                        modified_line = f"{var_name.rstrip()} = {replace_str}"
                    else:
                        # Handle non-assignment JSON
                        modified_line = line.replace(find, json.dumps(replace))
                else:
                    # Simple string replacement
                    modified_line = line.replace(find, str(replace))
                break
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