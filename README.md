# kubee — Simple Multi-Cluster Kubernetes Cli Tool

---
## Overview

**kubee** is a lightweight command-line tool written in **bash shell** for managing multiple Kubernetes clusters.  
It uses **AES-256-CBC encryption** to securely store kubeconfig files, combined with password input or configuration variables, enabling safe multi-cluster switching and namespace management.


## Features

- 🔐 **Encrypt & Decrypt kubeconfig**
    - Uses OpenSSL AES-256-CBC to securely store kubeconfig files, preventing plaintext exposure.
    - Global configuration is stored in `/etc/.kubee`, compatible with multi-user environments.

- 🌀 **Multi-Cluster Switching**
    - Each cluster maintains an independent encrypted kubeconfig file for quick switching.

- ⚙️ **Integrated Commands**
    - Supports:
        - `kubectl`
        - `helm`

- 📁 **Command Shortcuts**
    - Default aliases can be defined in `/etc/profile.d/kubee-aliases.sh` for simplified usage.

---

## How It Works

- Each cluster’s kubeconfig is stored as an encrypted file `config-<cluster>.enc`.
- During command execution, it decrypts (via password input or automatically) to a temporary file with `mktemp`.
- Commands are natively linked to `kubectl` and `helm`.
- Configuration is managed globally in `/etc/.kubee`.
