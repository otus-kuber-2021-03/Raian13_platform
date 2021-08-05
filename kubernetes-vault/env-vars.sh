#!/bin/bash

export VAULT_SA_NAME=$(kubectl get sa vault-auth -o jsonpath="{.secrets[*]['name']}")

export SA_JWT_TOKEN=$(kubectl get secret $VAULT_SA_NAME -o jsonpath="{.data.token}" | base64 --decode; echo)

export SA_CA_CRT=$(kubectl get secret $VAULT_SA_NAME -o jsonpath="{.data['ca\.crt']}" | base64 --decode; echo)
 
export K8S_HOST=$(kubectl cluster-info | grep 'Kubernetes control' | awk '/https/ {print $NF}' | sed 's/\x1b\[[0-9;]*m//g')