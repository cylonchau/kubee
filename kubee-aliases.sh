k-help() {
  echo -e "\nAvailable Aliases:"
  echo "------------------"
  local source_file="${BASH_SOURCE[0]:-/etc/profile.d/kubee-aliases.sh}"
  if [[ -f "$source_file" ]]; then
    grep "^alias " "$source_file" | sed -E "s/alias ([^=]+)='([^']*)'[[:space:]]*#?[[:space:]]*(.*)/\1 	 \2 	 \3/" | column -t -s '	'
  else
    echo "Error: Alias source file not found at $source_file"
  fi
}

k() {
  # Handle help subcommand to show alias help
  if [[ "${1:-}" == "help" ]]; then
    k-help
    return 0
  fi

  local args=()
  local namespace=""
  local encrypt_file=""

  # Parse arguments for -n and -e
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -n)
        if [[ -n "$2" ]]; then
          namespace="$2"
          args+=("--namespace" "$namespace")
          shift 2
        else
          echo "Error: -n requires a namespace"
          return 1
        fi
        ;;
      -e)
        if [[ -n "$2" ]]; then
          encrypt_file="$2"
          args+=("--encrypt" "$encrypt_file")
          shift 2
        else
          echo "Error: -e requires a kubeconfig file"
          return 1
        fi
        ;;
      *)
        args+=("$1")
        shift
        ;;
    esac
  done

  /usr/sbin/kubee "${args[@]}"
}

# h function for helm, handling -n option
h() {
  local args=()
  local namespace=""

  # Parse arguments for -n
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -n)
        if [[ -n "$2" ]]; then
          namespace="$2"
          args+=("--namespace" "$namespace")
          shift 2
        else
          echo "Error: -n requires a namespace"
          return 1
        fi
        ;;
      *)
        args+=("$1")
        shift
        ;;
    esac
  done

  /usr/sbin/kubee helm "${args[@]}"
}

# Pod-related aliases
alias kp='k get pod'          # Get pods
alias kpo='k get pod -owide'  # Get pods
alias kpa='k get pod -A'      # Get pods (all namespaces)
alias kpy='k get pod -oyaml'  # Get pods output yaml
alias kdp='k describe pod'    # Describe pod
alias kpy='k get pod -oyaml'  # Get pods output yaml
alias kep='k edit pod'        # Edit pod
alias kdelp='k delete pod'    # Delete pod
alias kexec='k exec -it'      # Exec into pod

# Log-related aliases
alias kl='k logs'             # Get logs
alias klf='k logs -f'         # Get logs with follow

# Deployment-related aliases
alias kd='k get deploy'         # Get deployments
alias kd='k get deploy -oyaml'  # Get deployments output yaml
alias kda='k get deploy -A'     # Get deployments (all namespaces)
alias kdd='k describe deploy'   # Describe deployment
alias ked='k edit deploy'       # Edit deployment
alias kdeld='k delete deploy'   # Delete deployment
alias kdy='k get deploy -o yaml' # Get deployments output yaml
alias krd='k rollout restart deploy' # Restart deployment

# Statefullset-related aliases
alias ksts='k get sts'        # Get deployments
alias kstsa='k get sts -A'    # Get deployments (all namespaces)
alias kstsd='k describe sts'  # Describe deployment
alias kests='k edit sts'      # Edit deployment
alias kdelsts='k delete sts'  # Delete deployment
alias kstsy='k get sts -o yaml' # Get statefulsets output yaml
alias krsts='k rollout restart sts' # Restart statefulset

# Service-related aliases
alias ksv='k get svc'         # Get services
alias ksva='k get svc -A'     # Get services (all namespaces)
alias kdsv='k describe svc'   # Describe service
alias kesv='k edit svc'       # Edit service
alias kdelsv='k delete svc'   # Delete service
alias kpf='k port-forward'    # Port-forward service
alias ksvy='k get svc -o yaml' # Get services output yaml

# Ingress-related aliases
alias king='k get ingress'    # Get ingresses
alias kinga='k get ingress -A' # Get ingresses (all namespaces)
alias kding='k describe ingress' # Describe ingress
alias keing='k edit ingress'  # Edit ingress
alias kdeling='k delete ingress' # Delete ingress

# ConfigMap-related aliases
alias kcm='k get configmap'   # Get configmaps
alias kcma='k get configmap -A' # Get configmaps (all namespaces)
alias kdcm='k describe configmap' # Describe configmap
alias kecm='k edit configmap' # Edit configmap
alias kdelcm='k delete configmap' # Delete configmap

# Secret-related aliases
alias ks='k get secret'       # Get secrets
alias ksa='k get secret -A'   # Get secrets (all namespaces)
alias kds='k describe secret' # Describe secret
alias kes='k edit secret'     # Edit secret
alias kdels='k delete secret' # Delete secret

# PersistentVolume-related aliases
alias kpv='k get pv'          # Get persistent volumes
alias kpva='k get pv -A'      # Get persistent volumes (all namespaces)
alias kdpv='k describe pv'    # Describe persistent volume
alias kdelpv='k delete pv'    # Delete persistent volume

# PersistentVolumeClaim-related aliases
alias kpvc='k get pvc'        # Get persistent volume claims
alias kpvca='k get pvc -A'    # Get persistent volume claims (all namespaces)
alias kdpvc='k describe pvc'  # Describe persistent volume claim
alias kdelpvc='k delete pvc'  # Delete persistent volume claim

# DaemonSet-related aliases
alias kds='k get daemonset'         # Get daemonsets
alias kdsa='k get daemonset -A'     # Get daemonsets (all namespaces)
alias kdds='k describe daemonset'   # Describe daemonset
alias kdelds='k delete daemonset'   # Delete daemonset
alias krestartds='k rollout restart daemonset' # Restart daemonset

# StatefulSet-related aliases
alias kss='k get statefulset'        # Get statefulsets
alias kssa='k get statefulset -A'    # Get statefulsets (all namespaces)
alias kdss='k describe statefulset'  # Describe statefulset
alias kdelss='k delete statefulset'  # Delete statefulset

# Job-related aliases
alias kj='k get job'          # Get jobs
alias kja='k get job -A'      # Get jobs (all namespaces)
alias kdj='k describe job'    # Describe job
alias kdelj='k delete job'    # Delete job

# CronJob-related aliases
alias kcj='k get cronjob'     # Get cronjobs
alias kcja='k get cronjob -A' # Get cronjobs (all namespaces)
alias kdcj='k describe cronjob' # Describe cronjob
alias kdelcj='k delete cronjob' # Delete cronjob

# Event-related aliases
alias ke='k get event'        # Get events
alias kea='k get event -A'    # Get events (all namespaces)

# Node-related aliases
alias kn='k get nodes'        # Get nodes
alias kdn='k describe node'   # Describe node
alias ktn='k top node'        # Top nodes (metrics)

# Namespace-related aliases
alias kns='k get namespaces'  # Get namespaces

# ClusterRole-related aliases
alias kcr='k get clusterrole' # Get clusterroles
alias kdcr='k describe clusterrole' # Describe clusterrole

# ClusterRoleBinding-related aliases
alias kcrb='k get clusterrolebinding' # Get clusterrolebindings
alias kdcrb='k describe clusterrolebinding' # Describe clusterrolebinding

# CRD-related aliases
alias kcrd='k get crd'        # Get custom resource definitions
alias kdcrd='k describe crd'  # Describe custom resource definition
alias kdelcrd='k delete crd'  # Delete custom resource definition

# Apply and delete (generic)
alias kaf='k apply -f'         # Apply from file
alias kdelf='k delete -f'      # Delete from file

# Top (metrics, namespace-specific)
alias kt='k top'              # Top resources
alias ktp='k top pod'         # Top resources
alias ktn='k top node'        # Top resources

# Helm-related aliases (examples, can be expanded)
alias hi='h install'          # Helm install
alias hu='h upgrade'          # Helm upgrade
alias hun='h uninstall'       # Helm uninstall
alias hl='h list'             # Helm list
alias hr='h repo'             # Helm repo
alias hs='h search'           # Helm search
alias hst='h status'          # Helm status
alias hh='h history'          # Helm history
alias hrb='h rollback'        # Helm rollback
alias ht='h test'             # Helm test