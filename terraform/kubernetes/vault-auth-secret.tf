# Copyright IBM Corp. 2018, 2026
# SPDX-License-Identifier: MPL-2.0

# replaces vault-auth-secret.yaml
# get the token and ca.crt for the vault-auth service account
resource "kubernetes_secret_v1" "vault-auth-secret" {
  metadata {
    name = "vault-auth-secret"
    annotations = {
      "kubernetes.io/service-account.name" = kubernetes_service_account_v1.vault-auth.metadata[0].name
    }
  }
  type = "kubernetes.io/service-account-token"
}