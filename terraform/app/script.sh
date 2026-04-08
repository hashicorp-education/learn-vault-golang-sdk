#!/bin/bash
# Copyright IBM Corp. 2018, 2026
# SPDX-License-Identifier: MPL-2.0

set -e

if minikube status &> /dev/null; then
# host.docker.internal connects back to the host machine from within docker/minikube
   external_vault_addr=$(minikube ssh "dig +short host.docker.internal" | tr -d '\r{}')
else
# Fallback to localhost if minikube is not running
   external_vault_addr="kubernetes"
fi

# Safely produce a JSON object containing the result value.
# jq will ensure that the value is properly quoted
# and escaped to produce a valid JSON string.
jq -n --arg eva "$external_vault_addr" '{"EXTERNAL_VAULT_ADDR":$eva}'