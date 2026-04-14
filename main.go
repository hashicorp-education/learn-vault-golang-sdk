// Copyright IBM Corp. 2018, 2026
// SPDX-License-Identifier: MPL-2.0

package main

import (
	"context"
	"log"
	"os"

	"github.com/gin-gonic/gin"

	vault "github.com/hashicorp/vault/api"
	auth "github.com/hashicorp/vault/api/auth/kubernetes"
)

func main() {
	config := vault.DefaultConfig()

	// initialize Vault client
	client, err := vault.NewClient(config)
	if err != nil {
		log.Printf("unable to initialize Vault client: %v", err)
		os.Exit(1)
	}

	// determine where the application is running and set the
	// Vault address and token accordingly
	if _, exists := os.LookupEnv("VAULT_ADDR"); exists {
		config.Address = os.Getenv("VAULT_ADDR")
	} else {
		log.Println("Cannot find a set VAULT_ADDR.  Exiting.")
		os.Exit(1)
	}

	// The service-account token will be read from the path where the token's
	// Kubernetes Secret is mounted. By default, Kubernetes will mount it to
	// /var/run/secrets/kubernetes.io/serviceaccount/token.
	k8sAuth, err := auth.NewKubernetesAuth(
		"vault-kube-auth-role",
	)
	if err != nil {
		log.Printf("unable to initialize Kubernetes auth method: %v", err)
		os.Exit(1)
	}

	authInfo, err := client.Auth().Login(context.Background(), k8sAuth)
	if err != nil {
		log.Printf("unable to log in with Kubernetes auth!: %v", err)
		os.Exit(1)
	}
	if authInfo == nil {
		log.Printf("no auth info was returned after login")
		os.Exit(1)
	}

	// set up Gin router
	router := gin.Default()
	router.SetTrustedProxies([]string{"127.0.0.1", "192.168.1.2", "10.0.0.0/8"})

	// using the token returned from Vault get secret from the default
	// mount path for KV v2 secret
	secret, err := client.KVv2("secret").Get(context.Background(), "myapp/api-key")
	if err != nil {
		log.Printf("unable to read secret: %v", err)
		os.Exit(1)
	}

	// data map can contain more than one key-value pair,
	// in this case we're just grabbing one of them
	value, ok := secret.Data["access_key"].(string)
	if !ok {
		log.Printf("value type assertion failed: %T %#v", secret.Data["access_key"], secret.Data["access_key"])
		os.Exit(1)
	}

	pass, ok := secret.Data["secret_access_key"].(string)
	if !ok {
		log.Printf("value type assertion failed: %T %#v", secret.Data["secret_access_key"], secret.Data["secret_access_key"])
		os.Exit(1)
	}

	log.Println("Access granted!")
	log.Printf("Retrieved secret value: %s, %s", value, pass)

	// Run Gin at the default port of 8080. The application will be accessible at http://localhost:8080 when port forwarding is set up.
	router.GET("/", func(c *gin.Context) {
		c.JSON(200, gin.H{
			"access_key":        value,
			"secret_access_key": pass,
		})
	})

	router.Run(":8080")
}
