# kubee — 简单的k8s多集群管理工具

---
中文 ｜ [English](README.md)

## 简介

`kubee` 是一个使用 bash shell实现的，用于管理多个 Kubernetes 集群的简单命令行工具。  
它通过 **AES-256-CBC 加密算法** 对 kubeconfig 文件进行加密存储，结合密码输入或配置文件变量，实现多集群安全切换、命名空间管理。

## 功能特性

- 🔐 **加密与解密 kubeconfig**
    - 使用 OpenSSL AES-256-CBC 加密保存配置，避免明文泄露。
    - 全局配置存放在 `/etc/.kubee`，兼容多用户系统。
- 🌀 **多集群切换**
    - 每个集群独立加密文件，支持快速切换。
- ⚙️ **集成命令**
    - kubectl
    - helm
- 📁 **命令简化**
  - 默认在 /etc/profile.d/kubee-aliases.sh 中自定义简化命令

## 工作原理

- 每个集群的 kubeconfig 都以 config-<cluster>.enc 加密保存；
- 执行命令时，解密（输入密码/自动）
- 原生关联kubectl/helm 命令
- 配置文件 /etc/.kubee