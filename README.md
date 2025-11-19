# Helm to YAML Converter

A bash script that converts Helm install commands with `--set` parameters into clean, readable YAML values files. Specifically designed for Kasten K10 deployments but can be adapted for other Helm charts.

## Description

This tool simplifies the process of managing Helm chart configurations by converting long, unwieldy `helm install` commands with multiple `--set` flags into well-structured YAML values files. Instead of maintaining complex command-line arguments, you can generate a reusable values file that's easier to version control, review, and maintain.

## Features

- **Automatic parsing**: Extracts all `--set` parameters from Helm commands
- **Nested structure support**: Properly handles dot-notation keys (e.g., `auth.tokenAuth.enabled=true`)
- **Array handling**: Supports array notation like `key[0]=value` and nested array objects
- **Type detection**: Automatically identifies and formats booleans, numbers, and strings
- **Clean YAML output**: Generates properly indented, readable YAML files
- **Special character handling**: Properly processes escaped commas (`\,`) in LDAP DNs and other values
- **Flexible input**: Works with both escaped (`\,`) and non-escaped (`,`) commas in quoted strings
- **Complex value support**: Handles LDAP Distinguished Names, URLs with special characters, and multi-line commands
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
  --set auth.ldap.bindDN="CN=Service Account\,CN=Users\,DC=prod\,DC=domain\,DC=net" \
  --set auth.k10AdminGroups[0]="CN=K10Admins\,CN=Users\,DC=prod\,DC=domain\,DC=net" \
  --set auth.ldap.groupSearch.userMatchers[0].userAttr="DN" \
  --set prometheus.server.enabled=false \
  --set ingress.create=true \
  --set ingress.host=kasten.example.com \
  --set datastore.parallelUploads=4
```

**Output** (`kasten-values.yml`):
```yaml
# Kasten K10 Values File  
# Generated on November 20, 2025
# Use with: helm install k10 kasten/k10 --namespace=kasten-io -f kasten-values.yml

auth:
  tokenAuth:
    enabled: true
  ldap:
    bindDN: "CN=Service Account,CN=Users,DC=prod,DC=domain,DC=net"
    groupSearch:
      userMatchers:
        -
          userAttr: DN
  k10AdminGroups:
    - "CN=K10Admins,CN=Users,DC=prod,DC=domain,DC=net"
prometheus:
  server:
    enabled: false
ingress:
  create: true
  host: kasten.example.com
datastore:
  parallelUploads: 4
```

**Install with generated file:**
```bash
helm install k10 kasten/k10 --namespace=kasten-io -f kasten-values.yml
```

## How It Works

1. Reads the Helm install command from standard input
2. Normalizes the command by removing line breaks and extra whitespace
3. Uses Python regex to extract all `--set` parameters, handling complex quoting
4. Processes escaped characters (e.g., `\,` in LDAP DNs becomes `,`)
5. Handles array notation by converting `key[0]` into proper YAML array syntax
6. Builds nested dictionary structure from dot-notation keys
7. Outputs properly formatted YAML with correct indentation and type handling

## Important Notes

### LDAP Distinguished Names and Escaped Commas

When working with LDAP Distinguished Names (DNs) or other values containing commas, the script handles both scenarios:

- **Escaped commas** (from `install.kasten.io`): `"CN=User\,CN=Users\,DC=domain\,DC=com"`
- **Regular commas** (manual entry): `"CN=User,CN=Users,DC=domain,DC=com"`

Both formats will be correctly converted to YAML. The script automatically unescapes `\,` to `,` when needed.

**Example:**
```bash
--set auth.ldap.bindDN="CN=Veeam Kasten\,CN=Users\,DC=prod\,DC=auv3\,DC=net"
```

Becomes:
```yaml
auth:
  ldap:
    bindDN: "CN=Veeam Kasten,CN=Users,DC=prod,DC=auv3,DC=net"
```

### Array Values

Array notation like `key[0]=value` is automatically converted to YAML array format:

**Example:**
```bash
--set auth.k10AdminGroups[0]="CN=admins,CN=Users,DC=domain,DC=com"
--set auth.ldap.groupSearch.userMatchers[0].userAttr="DN"
```

Becomes:
```yaml
auth:
  k10AdminGroups:
    - "CN=admins,CN=Users,DC=domain,DC=com"
  ldap:
    groupSearch:
      userMatchers:
        -
          userAttr: DN
```

## License

Open source - free to use and modify.
