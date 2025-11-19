#!/bin/bash

# helm-to-yaml.sh - Convert Kasten Helm install command to values YAML
# Usage: Paste your helm install command from install.kasten.io and run this script

echo "Paste your Helm install command and press Ctrl+D when done:"
echo ""

# Read the entire command
HELM_CMD=$(cat)

# Normalize the command by removing line breaks and extra spaces
HELM_CMD=$(echo "$HELM_CMD" | tr '\n' ' ' | sed 's/  */ /g')

# Create a temporary file to store the command
TEMP_CMD=$(mktemp)
echo "$HELM_CMD" > "$TEMP_CMD"

# Process everything in Python for better handling of complex quoting and escaping
python3 - "$TEMP_CMD" > kasten-values.yml << 'ENDPYTHON'
import sys
import re
from collections import OrderedDict
import datetime

def set_nested(d, keys, value):
    """Set value in nested dictionary"""
    for key in keys[:-1]:
        d = d.setdefault(key, OrderedDict())
    d[keys[-1]] = value

def print_yaml(d, indent=0):
    """Print nested dictionary as YAML"""
    for key, value in d.items():
        if isinstance(value, dict):
            print('  ' * indent + f'{key}:')
            print_yaml(value, indent + 1)
        elif isinstance(value, list):
            print('  ' * indent + f'{key}:')
            for item in value:
                if isinstance(item, dict):
                    print('  ' * (indent + 1) + '-')
                    print_yaml(item, indent + 2)
                else:
                    # Handle boolean and numeric values in lists
                    if isinstance(item, str) and item.lower() in ('true', 'false'):
                        item = item.lower()
                    elif isinstance(item, str) and item.isdigit():
                        item = int(item)
                    # Quote strings that need quoting
                    if isinstance(item, str) and needs_quoting(item):
                        print('  ' * (indent + 1) + f'- "{item}"')
                    else:
                        print('  ' * (indent + 1) + f'- {item}')
        else:
            # Handle boolean and numeric values
            if isinstance(value, str):
                if value.lower() in ('true', 'false'):
                    value = value.lower()
                elif value.isdigit():
                    value = int(value)
                elif needs_quoting(value):
                    value = f'"{value}"'
            print('  ' * indent + f'{key}: {value}')

def needs_quoting(s):
    """Check if a string needs to be quoted in YAML"""
    if not isinstance(s, str):
        return False
    # Quote if contains special characters or looks like a DN
    special_chars = [':', ',', '[', ']', '{', '}', '#', '&', '*', '!', '|', '>', '\'', '"', '%', '@', '\\']
    return any(c in s for c in special_chars) or s.startswith('CN=') or s.startswith('DC=')

# Read the helm command
with open(sys.argv[1], 'r') as f:
    helm_cmd = f.read()

# Find all --set parameters, handling quoted and unquoted values
# This regex captures: --set key="value" or --set key=value
# It handles escaped characters within quotes
pattern = r'--set\s+([^=\s]+)=("(?:[^"\\]|\\.)*"|[^\s\\]+)'

matches = re.findall(pattern, helm_cmd)

# Build the nested values structure
values = OrderedDict()

for key, value in matches:
    # Remove outer quotes if present
    if value.startswith('"') and value.endswith('"'):
        value = value[1:-1]
    
    # Remove trailing backslash if present (from line continuation)
    value = value.rstrip('\\').strip()
    
    # Unescape backslash-escaped characters (like \,)
    value = value.replace('\\,', ',').replace('\\\\', '\\')
    
    # Handle array indices like key[0]=value
    if '[' in key and ']' in key:
        # Split key into parts and array index
        # Example: auth.k10AdminGroups[0] -> ['auth', 'k10AdminGroups', '0']
        parts = key.replace('[', '.').replace(']', '').split('.')
        
        # Find where the array index is
        array_index = None
        base_keys = []
        array_key = None
        remaining_keys = []
        
        for i, part in enumerate(parts):
            if part.isdigit():
                array_index = int(part)
                array_key = parts[i-1] if i > 0 else None
                base_keys = parts[:i-1] if i > 0 else []
                remaining_keys = parts[i+1:] if i+1 < len(parts) else []
                break
        
        # Navigate to the parent of the array
        current = values
        for k in base_keys:
            current = current.setdefault(k, OrderedDict())
        
        # Create or get the array
        if array_key:
            if array_key not in current:
                current[array_key] = []
            
            # Extend array if needed
            while len(current[array_key]) <= array_index:
                current[array_key].append(None)
            
            # Set the value
            if remaining_keys:
                # Nested object in array (e.g., userMatchers[0].userAttr)
                if current[array_key][array_index] is None:
                    current[array_key][array_index] = OrderedDict()
                nested = current[array_key][array_index]
                set_nested(nested, remaining_keys, value)
            else:
                # Simple value in array
                current[array_key][array_index] = value
    else:
        # Regular key=value (no array)
        keys = key.split('.')
        set_nested(values, keys, value)

# Print the YAML header
print("# Kasten K10 Values File  ")
print(f"# Generated on {datetime.datetime.now().strftime('%c')}")
print("# Use with: helm install k10 kasten/k10 --namespace=kasten-io -f kasten-values.yml")
print()

# Print as YAML
print_yaml(values)
ENDPYTHON

# Clean up
rm -f "$TEMP_CMD"

echo ""
echo "✅ YAML file generated: kasten-values.yml"
echo ""
echo "To install Kasten using this file, run:"
echo "helm install k10 kasten/k10 --namespace=kasten-io -f kasten-values.yml"
