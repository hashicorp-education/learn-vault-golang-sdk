# Copyright IBM Corp. 2018, 2026
# SPDX-License-Identifier: MPL-2.0

# replaces vault-auth-service-account.yaml
resource "kubernetes_service_account_v1" "vault-auth" {
  metadata {
    name = "vault-auth"
  }
}

resource "kubernetes_cluster_role_binding_v1" "role-tokenreview-binding" {
  metadata {
    name = "role-tokenreview-binding"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "system:auth-delegator"
  }
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account_v1.vault-auth.metadata[0].name
    namespace = "default"
  }
}