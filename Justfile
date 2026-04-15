# Copyright IBM Corp. 2018, 2026
# SPDX-License-Identifier: MPL-2.0

set shell := ["bash", "-c"]
set positional-arguments
# load environment variables from .env file and require them to be set
# set dotenv-load 
set dotenv-required

image_name := "vault-sdk-go-app:latest"

alias test-docker := test

default: all
all: version build start-vault deploy-k8s status test clean
test-tutorial-path: build start-vault deploy-image-from-github status clean
clean-all: clean

[group('k8s')]
version:
   @echo ">> running $0"
   vault version
   docker --version
   kubectl version --client
   minikube version

[group('k8s')]
build: clean
   @echo ">> running $0"
   docker build -t {{image_name}} .

[group('k8s')]
deploy-k8s:
   @echo ">> running $0"
   ./vault-setup.sh
   kubectl get  secret vault-auth-secret -o json | jq -r ".data.token" | base64 --decode > token
   minikube image load {{image_name}}
   sleep 5
   kubectl apply -f manifests/go-app.yaml

   echo "kubectl port-forward pod/vault-client 8080:8080"

[group('k8s')]
deploy-image-from-github:clean
   @echo ">> running $0"
   ./vault-setup.sh
   docker pull ghcr.io/hashicorp-education/learn-vault-golang-sdk/vault-sdk-go-app:latest
   kubectl get  secret vault-auth-secret -o json | jq -r ".data.token" | base64 --decode > token
   minikube image load {{image_name}}
   sleep 5
   kubectl apply -f manifests/go-app.yaml

   echo "kubectl port-forward pod/vault-client 8080:8080"

[group('k8s')]
status:
   @echo ">> running $0"
   kubectl get pods
   @source <(grep "export VAULT_" vault.log | sed -E 's/^[[:space:]]*\$[[:space:]]*//')
   vault status

[group('exe')]
test:
   @echo ">> running $0"
   curl http://localhost:8080

[group('k8s')]
test-k8s:
   @echo ">> running $0"
   kubectl exec -it vault-client -- curl http://localhost:8080

[group('k8s')]
clean:
   @echo ">> running $0"
   kubectl delete -f manifests/go-app.yaml || true
   kubectl delete -f manifests/vault-auth-service-account.yaml || true
   kubectl delete -f manifests/vault-auth-secret.yaml || true
   minikube image rm {{image_name}} || true
   minikube image rm ghcr.io/hashicorp-education/learn-vault-golang-sdk/vault-sdk-go-app:latest || true
   docker stop $(docker ps -aq --filter name=reference=ghcr.io/hashicorp-education/learn-vault-golang-sdk/vault-sdk-go-app) || true
   docker stop $(docker ps -aq --filter name=reference={{image_name}}) || true
   docker image rm {{image_name}} || true
   docker image rm $(docker image ls --filter "reference=ghcr.io/hashicorp-education/learn-vault-golang-sdk/vault-sdk-go-app" --format {{"{{.ID}}/"}}) || true

[group('k8s')]
clean-images-k8s:
   @echo ">> running $0"
   minikube image rm ghcr.io/hashicorp-education/learn-vault-golang-sdk/vault-sdk-go-app:latest || true
   # docker image ls --filter "reference=ghcr.io/hashicorp-education/learn-vault-golang-sdk/vault-sdk-go-app" --format \"{{{{.ID}}\"
   docker image rm $(docker image ls --filter "reference=ghcr.io/hashicorp-education/learn-vault-golang-sdk/vault-sdk-go-app" --format "{{{{.ID}}") || true

[group('default')]
start-vault:
   @echo ">> running $0"
   nohup $(brew --prefix vault)/bin/vault server -dev -dev-root-token-id root -dev-tls -dev-tls-san=192.168.65.254 -dev-tls-cert-dir=certs > vault.log 2>&1 &
   sleep 2