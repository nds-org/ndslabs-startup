#!/bin/bash

#
# Remove basic auth secrets
# Migrate ingress rules from basic auth to SSO
#

DOMAIN=$1
signin_url="https://${DOMAIN}/login/#/"
auth_url="https://${DOMAIN}/cauth/auth"

set -e

KUBECTL_BIN='kubectl'

ECHO='echo -e -n'


## Loop over all namespaces
USERS=$($KUBECTL_BIN get ns --no-headers | grep -v admin | grep -v kube-system | grep -v default | awk '{print $1}')
for namespace in $USERS; do
   $ECHO "Removing basic-auth secret for $namespace:\n"
   $KUBECTL_BIN delete secret basic-auth --namespace=${namespace} || true

   $ECHO "Migrating ingress for $namespace\n"
   INGRESS=$($KUBECTL_BIN get ingress --all-namespaces --no-headers | grep -v default | grep -v kube-system | awk '{print $2}')
   for ingress in $INGRESS; do
       $ECHO "Migrating ingress $INGRESS\n"
       $KUBECTL_BIN get ingress $ingress --namespace=$namespace --no-headers -o json |  jq ".metadata.annotations={}" | jq ".metadata.annotations={\"nginx.ingress.kubernetes.io/auth-signin\":\"$signin_url\", \"nginx.ingress.kubernetes.io/auth-url\": \"$auth_url\"}" | $KUBECTL_BIN replace --namespace=${namespace} -f -
   done  
done
