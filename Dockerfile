# Copyright IBM Corp. 2018, 2026
# SPDX-License-Identifier: MPL-2.0

# syntax=docker/dockerfile:1

FROM golang:1.25
WORKDIR /app
COPY go.mod go.sum ./
COPY certs/vault-ca.pem /usr/local/share/ca-certificates/my-ca.crt
RUN apt-get update && apt-get install -y ca-certificates && update-ca-certificates
RUN go mod download
COPY *.go ./
ADD templates /app/templates
RUN CGO_ENABLED=0 GOOS=linux go build -o test-vault-client
EXPOSE 8080
CMD ["./test-vault-client"]