# Helm to YAML Converter

A bash script that converts Helm install commands with `--set` parameters into clean, readable YAML values files. Specifically designed for Kasten K10 deployments but can be adapted for other Helm charts.

## Description

This tool simplifies the process of managing Helm chart configurations by converting long, unwieldy `helm install` commands with multiple `--set` flags into well-structured YAML values files. Instead of maintaining complex command-line arguments, you can generate a reusable values file that's easier to version control, review, and maintain.

## Features

- **Automatic parsing**: Extracts all `--set` parameters from Helm commands
- **Nested structure support**: Properly handles dot-notation keys (e.g., `auth.tokenAuth.enabled=true`)
- **Type detection**: Automatically identifies and formats booleans, numbers, and strings
- **Clean YAML output**: Generates properly indented, readable YAML files
- **Comma-separated values**: Handles multiple values in a single `--set` parameter
- **Ready to use**: Generated file includes usage instructions as comments

## Requirements

- Bash shell
- Python 3 (used for reliable YAML generation)
- Helm (for using the generated values file)

## Usage

1. Make the script executable:
   ```bash
   chmod +x helm-to-yaml.sh
   ```

2. Run the script:
   ```bash
   ./helm-to-yaml.sh
   ```

3. Paste your Helm install command when prompted (e.g., from install.kasten.io)

4. Press `Ctrl+D` when done

5. The script will generate `kasten-values.yml` in the current directory

### Example

**Input:**
```bash
helm install k10 kasten/k10 --namespace=kasten-io \
  --set auth.tokenAuth.enabled=true \
  --set prometheus.server.enabled=false \
  --set ingress.create=true \
  --set ingress.host=kasten.example.com
```

**Output** (`kasten-values.yml`):
```yaml
# Kasten K10 Values File  
# Generated on November 19, 2025
# Use with: helm install k10 kasten/k10 --namespace=kasten-io -f kasten-values.yml

auth:
  tokenAuth:
    enabled: true
prometheus:
  server:
    enabled: false
ingress:
  create: true
  host: kasten.example.com
```

**Install with generated file:**
```bash
helm install k10 kasten/k10 --namespace=kasten-io -f kasten-values.yml
```

## How It Works

1. Reads the Helm install command from standard input
2. Extracts all `--set` parameters using regex patterns
3. Handles both quoted and unquoted parameter values
4. Uses Python to parse key-value pairs and build nested dictionary structure
5. Outputs properly formatted YAML with correct indentation and type handling

## Benefits

- **Version Control**: YAML files are easier to track in Git than long command lines
- **Code Review**: Team members can easily review configuration changes
- **Reusability**: Use the same values file across multiple environments with minor modifications
- **Documentation**: The YAML structure is self-documenting and easier to understand
- **Consistency**: Reduces errors from manually typing long Helm commands

## License

Open source - free to use and modify.
