#!/bin/bash

# helm-to-yaml.sh - Convert Kasten Helm install command to values YAML
# Usage: Paste your helm install command from install.kasten.io and run this script

echo "Paste your Helm install command and press Ctrl+D when done:"
echo ""

# Read the entire command
HELM_CMD=$(cat)

# Create the header
cat > kasten-values.yml << EOF
# Kasten K10 Values File  
# Generated on $(date)
# Use with: helm install k10 kasten/k10 --namespace=kasten-io -f kasten-values.yml

EOF

# Create a temporary file to store key-value pairs
TEMP_PAIRS=$(mktemp)

# Extract --set parameters and clean them up
echo "$HELM_CMD" | grep -oE -- '--set[[:space:]]+"[^"]+"' | sed 's/--set[[:space:]]*"//g' | sed 's/"[[:space:]]*$//g' > "$TEMP_PAIRS"
echo "$HELM_CMD" | grep -oE -- '--set[[:space:]]+[^[:space:]\\-]+' | grep -v '"' | sed 's/--set[[:space:]]*//g' >> "$TEMP_PAIRS"

# Process the pairs and build YAML using Python for reliable nested structure
python3 - "$TEMP_PAIRS" >> kasten-values.yml << 'ENDPYTHON'
import sys
from collections import OrderedDict

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
        else:
            # Handle boolean and numeric values
            if value.lower() in ('true', 'false'):
                value = value.lower()
            elif value.isdigit():
                value = int(value)
            print('  ' * indent + f'{key}: {value}')

# Read the temp file
values = OrderedDict()
with open(sys.argv[1], 'r') as f:
    for line in f:
        line = line.strip()
        if not line or '=' not in line:
            continue
        
        # Handle comma-separated values
        for param in line.split(','):
            param = param.strip()
            if '=' in param:
                key, value = param.split('=', 1)
                keys = key.strip().split('.')
                set_nested(values, keys, value.strip())

# Print as YAML
print_yaml(values)
ENDPYTHON

# Clean up
rm -f "$TEMP_PAIRS"

echo ""
echo "✅ YAML file generated: kasten-values.yml"
echo ""
echo "To install Kasten using this file, run:"
echo "helm install k10 kasten/k10 --namespace=kasten-io -f kasten-values.yml"