# Copyright IBM Corp. 2018, 2026
# SPDX-License-Identifier: MPL-2.0

terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.0"
    }
    external = {
      source  = "hashicorp/external"
      version = "2.3.5"
    }
    vault = {
      source  = "hashicorp/vault"
      version = ">= 5.6.0"
    }
  }
}

provider "kubernetes" {
  config_path    = "~/.kube/config"
#   config_context = "minikube"
}
