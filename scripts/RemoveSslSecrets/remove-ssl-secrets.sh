#!/bin/bash

#
# For all non-admin namespaces, remove the TLS certificate secret
#
set -e

KUBECTL_BIN='kubectl'

ECHO='echo -e -n'


$KUBECTL_BIN delete secret ndslabs-tls-secret --namespace=kube-system

# Loop over the rest of the namespaces to update TLS in each one
USERS=$($KUBECTL_BIN get secret --all-namespaces | grep tls-secret | grep -v default | grep -v kube-system | awk '{print $1}')
for namespace in $USERS; do
        $ECHO "Removing TLS certificate for $namespace: "
        $KUBECTL_BIN delete secret ${namespace}-tls-secret --namespace=${namespace} || true
done
