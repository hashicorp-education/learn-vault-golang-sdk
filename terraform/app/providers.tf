# Copyright IBM Corp. 2018, 2026
# SPDX-License-Identifier: MPL-2.0

terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.0"
    }
   }
}

provider "kubernetes" {
  config_path    = "~/.kube/config"
#   config_context = "minikube"
}
