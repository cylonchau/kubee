# kubee

[![Build](https://github.com/cylonchau/kubee/actions/workflows/release.yaml/badge.svg?style=flat-square)](https://github.com/cylonchau/kubee/actions)
[![Rocky Linux](https://img.shields.io/badge/Rocky%20Linux-9%20|%2010-10b981?style=flat-square&logo=rockylinux)](https://rockylinux.org/)
[![AlmaLinux](https://img.shields.io/badge/AlmaLinux-8%20|%209-ff5252?style=flat-square&logo=almalinux)](https://almalinux.org/)
[![CentOS](https://img.shields.io/badge/CentOS-7-262524?style=flat-square&logo=centos&logoColor=white)](https://www.centos.org/)
[![License](https://img.shields.io/github/license/cylonchau/kubee?style=flat-square&color=orange)](https://github.com/cylonchau/kubee/blob/main/LICENSE)

**kubee** is a lightweight command-line toolkit written in Bash shell for managing multiple Kubernetes clusters with security and ease.

## Overview

It uses **AES-256-CBC encryption** to securely store kubeconfig files, combined with password input or configuration variables, enabling safe multi-cluster switching and namespace management.

## Usage Guide

### 1. Initialize Configuration
Set your master password in `/etc/.kubee` (or use the default if allowed):
```bash
# Example /etc/.kubee content
KUBE_PASS="your-secure-password"
USE_PASSWORD=false  # Set to true to prompt for password every time
```

### 2. Add Cluster (Encryption)
Encrypt an existing kubeconfig file for a new cluster:
```bash
kubee -e /path/to/cluster-kubeconfig your_cluster_name # default path is ～/.kube/config-your_cluster_name.enc
```

### 3. Basic Commands
Run `kubectl` commands through `kubee`:
```bash
# Get pods in default namespace
kp

# Specify a default namespace
k -n kube-system

# Use a specific encrypted kubeconfig
k -e config your-cluster
```

### 4. Helm Integration
Use helm with automatic decryption:
```bash
h list
h install my-release bitnami/nginx -n web
```

### 5. Help & Aliases
View all available pre-defined shortcuts:
```bash
k help # print support commands.
k -h   # print kubee command help.
```

## Features

   **Secure Kubeconfig Management**
    - Uses OpenSSL AES-256-CBC to encrypt kubeconfig files, preventing plaintext exposure.
    - Global configuration stored in `/etc/.kubee`, compatible with multi-user environments.

   **Multi-Cluster Switching**
    - Each cluster maintains an independent encrypted kubeconfig file for quick switching.

   **Power Tool Integration**
    - Seamlessly supports `kubectl` and `helm`.

**Smart Command Shortcuts**
    - Pre-defined aliases in `/etc/profile.d/kubee-aliases.sh` to boost productivity.

## How It Works

1. **Storage**: Each cluster’s kubeconfig is stored as an encrypted file `config-<cluster>.enc`.
2. **Execution**: Decrypts (via password or config) to a temporary file using `mktemp` only during command run.
3. **Native Feel**: Commands are natively passed to your local `kubectl` and `helm` binaries.
4. **Global Config**: Management settings are centralized in `/etc/.kubee`.
