set shell := ["bash", "-c"]
set positional-arguments

default: all
all: version build deploy-k8s status test clean
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
   docker build -t ghcr.io/hashicorp-education/learn-vault-golang-sdk/vault-sdk-go-app:latest .

[group('k8s')]
deploy-k8s:
   @echo ">> running $0"
   ./vault-setup.sh
   kubectl get  secret vault-auth-secret -o json | jq -r ".data.token" | base64 --decode > token
   minikube image load ghcr.io/hashicorp-education/learn-vault-golang-sdk/vault-sdk-go-app:latest
   sleep 5
   kubectl apply -f manifests/go-app.yaml

   echo "kubectl port-forward pod/vault-client 8080:8080"

[group('k8s')]
status:
   @echo ">> running $0"
   kubectl get pods

[group('exe')]
test:
   @echo ">> running $0"
   go run main.go

[group('docker')]
test-docker:
   @echo ">> running $0"
   docker run -d --name vault-sdk-go-app --publish 8080:8080 ghcr.io/hashicorp-education/learn-vault-golang-sdk/vault-sdk-go-app:latest


[group('k8s')]
test-k8s:
   @echo ">> running $0"
   kubectl apply -f k8s-auth/go-app.yaml
   echo "kubectl port-forward pod/vault-client 8080:8080"

[group('k8s')]
clean:
   @echo ">> running $0"
   kubectl delete -f go-app.yaml || true
   kubectl delete -f vault-auth-service-account.yaml || true
   kubectl delete -f vault-auth-secret.yaml || true
   minikube image rm ghcr.io/hashicorp-education/learn-vault-golang-sdk/vault-sdk-go-app:latest || true
   docker stop $(docker ps -aq --filter name=reference=ghcr.io/hashicorp-education/learn-vault-golang-sdk/vault-sdk-go-app) || true
   docker image rm $(docker image ls --filter "reference=ghcr.io/hashicorp-education/learn-vault-golang-sdk/vault-sdk-go-app" --format {{"{{.ID}}/"}}) || true

[group('k8s')]
clean-images-k8s:
   @echo ">> running $0"
   minikube image rm ghcr.io/hashicorp-education/learn-vault-golang-sdk/vault-sdk-go-app:latest || true
   # docker image ls --filter "reference=ghcr.io/hashicorp-education/learn-vault-golang-sdk/vault-sdk-go-app" --format \"{{{{.ID}}\"
   docker image rm $(docker image ls --filter "reference=ghcr.io/hashicorp-education/learn-vault-golang-sdk/vault-sdk-go-app" --format "{{{{.ID}}") || true
