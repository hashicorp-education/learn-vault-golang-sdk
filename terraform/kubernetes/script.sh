#!/bin/bash
# Copyright IBM Corp. 2018, 2026
# SPDX-License-Identifier: MPL-2.0

set -e

IP=$(kubectl config view --raw --minify --flatten --output 'jsonpath={.clusters[].cluster.server}')

# Safely produce a JSON object containing the result value.
# jq will ensure that the value is properly quoted
# and escaped to produce a valid JSON string.
jq -n --arg ip "$IP" '{"K8S_HOST":$ip}'