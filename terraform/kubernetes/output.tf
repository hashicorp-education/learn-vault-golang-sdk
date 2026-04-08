# Copyright IBM Corp. 2018, 2026
# SPDX-License-Identifier: MPL-2.0

output "ENVIRONMENT_VARIABLES" {
  description = "Environment variables to help Vault access the k8s cluster"
  value       = <<EOF
   export SA_SECRET_NAME=${kubernetes_secret_v1.vault-auth-secret.metadata[0].name} \
   SA_JWT_TOKEN=${nonsensitive("${kubernetes_secret_v1.vault-auth-secret.data.token}")} \
   SA_CA_CRT="${nonsensitive("${kubernetes_secret_v1.vault-auth-secret.data["ca.crt"]}")}" \
   K8S_HOST=${data.external.get-k8s-host.result["K8S_HOST"]}
EOF
}
