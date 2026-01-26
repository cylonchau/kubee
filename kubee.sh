#!/bin/bash
set -euo pipefail

CONFIG_FILE=/etc/.kubee
KUBEDIR=~/.kube
DEFAULT_CLUSTER="default"
ENCRYPTED_SUFFIX=".enc"

# Function to clean up temporary file
cleanup() {
  rm -f "$TMP_KUBECONFIG" 2>/dev/null
}
trap cleanup EXIT

# Function to load config
load_config() {
  if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "Error: Config file not found at $CONFIG_FILE"
    exit 1
  fi
  source "$CONFIG_FILE"
  CLUSTER="${CLUSTER:-$DEFAULT_CLUSTER}"
  
  # Determine encrypted file path with fallback
  if [[ -n "${KUBECONFIG:-}" ]]; then
    ENCRYPTED_FILE="$KUBECONFIG"
  else
    ENCRYPTED_FILE="$KUBEDIR/config-${CLUSTER}$ENCRYPTED_SUFFIX"
    # Fallback for default cluster: if config-default.enc doesn't exist, try config.enc
    if [[ "$CLUSTER" == "$DEFAULT_CLUSTER" && ! -f "$ENCRYPTED_FILE" ]]; then
      local legacy_file="$KUBEDIR/config$ENCRYPTED_SUFFIX"
      if [[ -f "$legacy_file" ]]; then
        ENCRYPTED_FILE="$legacy_file"
      fi
    fi
  fi
  
  TMP_KUBECONFIG=$(mktemp)
}

# Function to set a variable in config file
set_config_var() {
  local key="$1"
  local val="$2"
  if grep -q "^$key=" "$CONFIG_FILE"; then
    sed -i "s|^$key=.*|$key=\"$val\"|" "$CONFIG_FILE"
  else
    echo "$key=\"$val\"" >> "$CONFIG_FILE"
  fi
}

# Function to prompt for password if enabled
get_password() {
  if [[ "${USE_PASSWORD:-false}" == "true" && -t 0 ]]; then
    read -s -p "Enter kubeconfig password for cluster $CLUSTER: " KUBE_PASS
    echo
    if [[ -z "$KUBE_PASS" ]]; then
      echo "Error: Password cannot be empty"
      exit 1
    fi
  elif [[ -z "${KUBE_PASS:-}" ]]; then
    echo "Error: KUBE_PASS not set in $CONFIG_FILE and password prompt is disabled or non-interactive"
    exit 1
  fi
}

# Function to display usage information
print_usage() {
  cat << EOF
Usage: $0 [option] | helm [helm arguments] | [kubectl arguments]
Options:
  -h, --help                                   Display this help message
  -c, --current                                Display the current cluster, kubeconfig, and default namespace
  -e, --encrypt <kubeconfig.yaml> [<cluster>]  Encrypt the specified kubeconfig file (optionally for a cluster)
  -d, --decrypt <output.yaml> [<cluster>]      Decrypt the encrypted kubeconfig to the specified output file (optionally for a cluster)
  -n, --namespace <namespace>                  Set the default namespace for the current cluster
  -s, --switch <cluster>                       Switch to the specified cluster
  -l, --list                                   List available clusters
Examples:
  $0 -c                           # Show current cluster, kubeconfig, and default namespace
  $0 -e ~/.kube/config mycluster  # Encrypt kubeconfig file for 'mycluster' and switch to it
  $0 -d output.yaml mycluster     # Decrypt 'mycluster' kubeconfig to output.yaml
  $0 -n my-namespace              # Set default namespace for current cluster
  $0 -s mycluster                 # Switch to 'mycluster'
  $0 -l                           # List clusters
  $0 get pods                     # Run kubectl command
  $0 helm list                    # Run helm command
EOF
  exit 0
}

# Function to display current cluster and namespace
show_current_cluster() {
  if [[ ! -f "$ENCRYPTED_FILE" ]]; then
    echo "Current cluster: $CLUSTER"
    echo "Kubeconfig file: $ENCRYPTED_FILE"
    echo "Kubeconfig file exists: No"
    echo "Default namespace: Unknown (kubeconfig file missing)"
    exit 0
  fi
  get_password
  openssl enc -aes-256-cbc -d -salt -in "$ENCRYPTED_FILE" -out "$TMP_KUBECONFIG" -pass pass:"$KUBE_PASS" 2>/dev/null || {
    echo "Error: Failed to decrypt kubeconfig. Check password or file integrity."
    exit 1
  }
  local namespace=$(KUBECONFIG="$TMP_KUBECONFIG" kubectl config view --minify -o jsonpath='{.contexts[0].context.namespace}' 2>/dev/null || echo "Not set")
  echo "Current cluster: $CLUSTER"
  echo "Kubeconfig file: $ENCRYPTED_FILE"
  echo "Default namespace: ${namespace:-Not set}"
  exit 0
}

# Function to encrypt kubeconfig
encrypt_kubeconfig() {
  if [[ $# -lt 1 || $# -gt 2 ]]; then
    echo "Error: Encrypt mode requires a kubeconfig file and optionally a cluster name"
    echo "Usage: $0 -e|--encrypt <kubeconfig.yaml> [<cluster>]"
    exit 1
  fi
  local input="$1"
  local target_cluster="${2:-$CLUSTER}"
  local target_enc="$KUBEDIR/config-${target_cluster}$ENCRYPTED_SUFFIX"
  get_password
  openssl enc -aes-256-cbc -salt -in "$input" -out "$target_enc" -pass pass:"$KUBE_PASS" 2>/dev/null
  echo "Encrypted kubeconfig saved to $target_enc"
  if [[ -n "$2" ]]; then
    set_config_var KUBECONFIG "$target_enc"
    set_config_var CLUSTER "$target_cluster"
    echo "Switched to cluster $target_cluster"
  fi
  exit 0
}

# Function to decrypt kubeconfig
decrypt_kubeconfig() {
  if [[ $# -lt 1 || $# -gt 2 ]]; then
    echo "Error: Decrypt mode requires an output file and optionally a cluster name"
    echo "Usage: $0 -d|--decrypt <output.yaml> [<cluster>]"
    exit 1
  fi
  local output="$1"
  local target_cluster="${2:-$CLUSTER}"
  local target_enc="${2:+$KUBEDIR/config-${target_cluster}$ENCRYPTED_SUFFIX}"
  target_enc="${target_enc:-$ENCRYPTED_FILE}"
  if [[ ! -f "$target_enc" ]]; then
    echo "Error: Encrypted kubeconfig not found at $target_enc"
    exit 1
  fi
  get_password
  openssl enc -aes-256-cbc -d -salt -in "$target_enc" -out "$output" -pass pass:"$KUBE_PASS" 2>/dev/null
  echo "Decrypted kubeconfig saved to $output"
  exit 0
}

# Function to set default namespace
set_namespace() {
  if [[ $# -ne 1 ]]; then
    echo "Error: Namespace option requires a namespace name"
    echo "Usage: $0 -n|--namespace <namespace>"
    exit 1
  fi
  if [[ ! -f "$ENCRYPTED_FILE" ]]; then
    echo "Error: Encrypted kubeconfig not found at $ENCRYPTED_FILE"
    exit 1
  fi
  get_password
  openssl enc -aes-256-cbc -d -salt -in "$ENCRYPTED_FILE" -out "$TMP_KUBECONFIG" -pass pass:"$KUBE_PASS" 2>/dev/null
  KUBECONFIG="$TMP_KUBECONFIG" kubectl config set-context --current --namespace="$1"
  openssl enc -aes-256-cbc -salt -in "$TMP_KUBECONFIG" -out "$ENCRYPTED_FILE" -pass pass:"$KUBE_PASS" 2>/dev/null
  echo "Default namespace set to $1 for cluster $CLUSTER"
  exit 0
}

# Function to switch cluster
switch_cluster() {
  if [[ $# -ne 1 ]]; then
    echo "Error: Switch requires a cluster name"
    echo "Usage: $0 -s|--switch <cluster>"
    exit 1
  fi
  local target_enc="$KUBEDIR/config-$1$ENCRYPTED_SUFFIX"
  if [[ ! -f "$target_enc" ]]; then
    echo "Warning: Encrypted kubeconfig not found for cluster $1 at $target_enc"
  fi
  set_config_var KUBECONFIG "$target_enc"
  set_config_var CLUSTER "$1"
  echo "Switched to cluster $1 (KUBECONFIG=$target_enc)"
  exit 0
}

# Function to list clusters
list_clusters() {
  local clusters=$(ls "$KUBEDIR"/config-*$ENCRYPTED_SUFFIX 2>/dev/null | sed "s|$KUBEDIR/config-||; s|$ENCRYPTED_SUFFIX||")
  if [[ -z "$clusters" ]]; then
    echo "No clusters found in $KUBEDIR"
  else
    echo "Available clusters:"
    echo "$clusters"
    echo "Current cluster: $CLUSTER"
  fi
  exit 0
}

# Function to run kubectl command
run_kubectl() {
  if [[ ! -f "$ENCRYPTED_FILE" ]]; then
    echo "Error: Encrypted kubeconfig not found at $ENCRYPTED_FILE"
    exit 1
  fi
  get_password
  openssl enc -aes-256-cbc -d -salt -in "$ENCRYPTED_FILE" -out "$TMP_KUBECONFIG" -pass pass:"$KUBE_PASS" 2>/dev/null || {
    echo "Error: Failed to decrypt kubeconfig. Check password or file integrity."
    exit 1
  }
  KUBECONFIG="$TMP_KUBECONFIG" kubectl "$@"
}

# Function to run helm command
run_helm() {
  if [[ ! -f "$ENCRYPTED_FILE" ]]; then
    echo "Error: Encrypted kubeconfig not found at $ENCRYPTED_FILE"
    exit 1
  fi
  get_password
  openssl enc -aes-256-cbc -d -salt -in "$ENCRYPTED_FILE" -out "$TMP_KUBECONFIG" -pass pass:"$KUBE_PASS" 2>/dev/null || {
    echo "Error: Failed to decrypt kubeconfig. Check password or file integrity."
    exit 1
  }
  KUBECONFIG="$TMP_KUBECONFIG" helm "$@"
}

# Load config
load_config

# Main logic using case
case "${1:-}" in
  -h|--help)
    print_usage
    ;;
  help)
    print_usage
    if [[ -f /etc/profile.d/kubee-aliases.sh ]]; then
      (source /etc/profile.d/kubee-aliases.sh && k-help)
    fi
    exit 0
    ;;
  -c|--current)
    show_current_cluster
    ;;
  -e|--encrypt)
    shift
    encrypt_kubeconfig "$@"
    ;;
  -d|--decrypt)
    shift
    decrypt_kubeconfig "$@"
    ;;
  -n|--namespace)
    shift
    set_namespace "$@"
    ;;
  -s|--switch)
    shift
    switch_cluster "$@"
    ;;
  -l|--list)
    list_clusters
    ;;
  helm)
    shift
    run_helm "$@"
    ;;
  "")
    # No arguments provided, show help
    print_usage
    ;;
  *)
    run_kubectl "$@"
    ;;
esac