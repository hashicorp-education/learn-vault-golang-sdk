# Copyright IBM Corp. 2018, 2026
# SPDX-License-Identifier: MPL-2.0

set dotenv-required

# List all available commands
default:
    @just --list

# Run all steps
alias all := run-all

# Run the entire tutorial workflow
run-all: precheck version set-up-lab vault-port-forward configure-k8s-vault build-deploy-app
## build-deploy-app verification
run-instruqt: configure-k8s-vault
#build-deploy-app verification

[group('default')]
precheck:
   #!/bin/bash
   echo ">> running $0"
   if pgrep -x "vault" > /dev/null
   then 
      echo "vault is running."
   else 
      echo "vault is NOT running."; 
      exit 1;
   fi


# Print versions of all tools used in the tutorial
version:
    @echo "=== Tool Versions ==="
    @vault version
    @kubectl version --client
    @docker --version
    @minikube version || true
    @k3s -v || true
    @git --version
    @jq --version
    @terraform version

env-vars:
    echo "export VAULT_ADDR=$VAULT_ADDR VAULT_CACERT=$VAULT_CACERT VAULT_TOKEN=$VAULT_TOKEN"

# Set up the lab environment
set-up-lab:
    @echo "=== Setting up the lab ==="
    echo "should here: git clone https://github.com/hashicorp-education/learn-vault-golang-sdk.git"
    cd learn-vault-golang-sdk/
    mkdir -p certs
    export VAULT_ADDR='https://127.0.0.1:8200' VAULT_CACERT='certs/vault-ca.pem' VAULT_TOKEN=root
    minikube start
    minikube status


vault-port-forward:
   @echo "=== Testing a thing ==="
   sleep 3
   nohup sh -c "kubectl port-forward pod/vault 8200:8200" < /dev/null > /dev/null 2>&1 &

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

build-deploy-app-k3s:
    @echo "=== Building and deploying the application ==="
    ls certs/
    terraform -chdir=terraform/app/ init
    VAULT_CACERT="$PWD/certs/vault-ca.pem" terraform -chdir=terraform/app/ apply -auto-approve
    kubectl get pods
    kubectl logs vault-client

build-deploy-app-instruqt:
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
    #  curl http://localhost:8080

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
    pkill kubectl || true

# curl --cacert /usr/local/share/ca-certificates/my-ca.crt  $VAULT_ADDR/v1/sys/seal-status