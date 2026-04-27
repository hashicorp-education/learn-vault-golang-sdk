# Copyright IBM Corp. 2018, 2026
# SPDX-License-Identifier: MPL-2.0

set dotenv-required

# List all available commands
default:
    @just --list

# Run all steps
alias all := run-all

# Run the entire tutorial workflow
run-all: version set-up-lab configure-k8s-vault build-deploy-app verification clean-up

# Print versions of all tools used in the tutorial
version:
    @echo "=== Tool Versions ==="
    @vault version
    @kubectl version --client
    @docker --version
    @minikube version
    @git --version
    @jq --version
    @terraform version

env-vars:
    echo "export VAULT_ADDR=$VAULT_ADDR VAULT_CACERT=$VAULT_CACERT VAULT_TOKEN=$VAULT_TOKEN"

# Set up the lab environment
set-up-lab:
    @echo "=== Setting up the lab ==="
    git clone https://github.com/hashicorp-education/learn-vault-golang-sdk.git || true
    cd learn-vault-golang-sdk/
    mkdir -p certs
    nohup vault server -dev -dev-root-token-id root -dev-tls -dev-tls-san=192.168.65.254 -dev-tls-cert-dir=certs > vault.log 2>&1 &
    sleep 3
    export VAULT_ADDR='https://127.0.0.1:8200' VAULT_CACERT='certs/vault-ca.pem' VAULT_TOKEN=root
    minikube start
    minikube status

# Configure Kubernetes and Vault resources
configure-k8s-vault:
    @echo "=== Configuring Kubernetes and Vault resources ==="
    terraform -chdir=terraform/kubernetes/ init
    VAULT_CACERT="$PWD/certs/vault-ca.pem" terraform -chdir=terraform/kubernetes/ apply -auto-approve
    kubectl get serviceaccount vault-auth
    kubectl get secret vault-auth-secret
    vault auth list
    vault policy read api-key-policy
    vault kv get secret/myapp/api-key
    vault read auth/kubernetes/config
    vault read auth/kubernetes/role/vault-kube-auth-role

# Review the Go application code
review-app:
    @echo "=== Review the application code ==="
    more main.go

# Build and deploy the application
build-deploy-app:
    @echo "=== Building and deploying the application ==="
    ls certs/
    docker build -t vault-sdk-go-app:latest .
    minikube image load vault-sdk-go-app:latest
    terraform -chdir=terraform/app/ init
    VAULT_CACERT="$PWD/certs/vault-ca.pem" terraform -chdir=terraform/app/ apply -auto-approve
    kubectl get pods
    kubectl logs vault-client

# Verification step - prints instructions only
verification:
    @echo "=== Verification Instructions ==="
    @echo "1. In a new terminal, run: kubectl port-forward pod/vault-client 8080:8080"
    @echo "2. In another terminal, run: curl http://localhost:8080"
    @echo "3. Expected output: {\"access_key\":\"appuser\",\"secret_access_key\":\"Su4t9mBFykMW29LLHsGH5g==\"}"

# Clean up all resources
clean-up:
    @echo "=== Cleaning up ==="
    terraform -chdir=terraform/app/ destroy --auto-approve || true
    VAULT_CACERT="$PWD/certs/vault-ca.pem" terraform -chdir=terraform/kubernetes/ destroy --auto-approve || true
    minikube stop || true
    minikube delete || true
    pkill vault || true
    rm -rf certs/ || true
    rm -f vault.log || true
