# Image k8s auth with SDK

Container with Kubernetes authentication and the Vault Go SDK.  It is used in the devdot tutorial for the Vault SDK.

## update image used in the tutorial

If you update Dockerfile, main.go or anyfile the `templates/` folder there is a github action to update the image.  Check the actions tab to see if the action was a success then it will be available through a git pull.

```
docker pull ghcr.io/mister-ken/github-action-test/k8s-vault-client:latest  
```

The the [package page](https://github.com/mister-ken/github-action-test/pkgs/container/github-action-test%2Fk8s-vault-client) for more details.
