# Copyright IBM Corp. 2018, 2026
# SPDX-License-Identifier: MPL-2.0

data "external" "get-k8s-host" {
  program = ["bash", "${path.module}/script.sh"]
}

data "vault_policy_document" "api-key-policy-document" {
  rule {
    path         = "secret/data/myapp/*"
    capabilities = ["read", "list"]
    description  = "allow all on secrets"
  }
}

resource "vault_policy" "api-key-policy" {
  name   = "api-key-policy"
  policy = data.vault_policy_document.api-key-policy-document.hcl
}

resource "vault_kv_secret_v2" "myapp-api-key-secret" {
  mount = "secret"
  name  = "myapp/api-key"
  data_json = jsonencode(
    {
      access_key        = "apppuser",
      secret_access_key = "suP3rS3cr3t!"
    }
  )
}

resource "vault_auth_backend" "kubernetes" {
  type = "kubernetes"
}

resource "vault_kubernetes_auth_backend_config" "k8s-auth-config" {
  backend = vault_auth_backend.kubernetes.path

  kubernetes_host    = data.external.get-k8s-host.result["K8S_HOST"]
  kubernetes_ca_cert = kubernetes_secret_v1.vault-auth-secret.data["ca.crt"]
  token_reviewer_jwt = kubernetes_secret_v1.vault-auth-secret.data.token
  issuer             = "https://kubernetes.default.svc.cluster.local"
}

resource "vault_kubernetes_auth_backend_role" "myapp-role" {
  backend                          = vault_auth_backend.kubernetes.path
  role_name                        = "vault-kube-auth-role"
  bound_service_account_names      = [kubernetes_service_account_v1.vault-auth.metadata[0].name]
  bound_service_account_namespaces = ["default"]
  token_policies                   = [vault_policy.api-key-policy.name]
  audience                         = "https://kubernetes.default.svc.cluster.local"
  token_ttl                        = 3600
}