# Copyright IBM Corp. 2018, 2026
# SPDX-License-Identifier: MPL-2.0

# replaces go-app.yaml
resource "kubernetes_pod_v1" "vault-client" {
  metadata {
    name      = "vault-client"
    namespace = "default"
  }
  spec {
    service_account_name = var.kube_service_name
    container {
      name  = "vault-client"
      image = "ghcr.io/hashicorp-education/learn-vault-golang-sdk/vault-sdk-go-app:latest"
      env {
        name = "VAULT_ADDR"
        value = local.external_vault_addr
      }
    }
  }

}