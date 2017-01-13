#!/bin/bash

echo -n "Enter the domain name for this server [$DOMAIN]: "
read domain
if [ -n "$domain" ]; then
    DOMAIN=$domain
fi

export DOMAIN

export APISERVER_HOST="www.$DOMAIN"
export APISERVER_PORT=443
export APISERVER_SECURE=true

# Stop Dev version of webui and a cloud9 container
kubectl delete svc,rc ndslabs-webui
kubectl delete svc,rc cloud9
kubectl delete ingress cloud9-ingress

# Start Prod version of webui
cat templates/webui.yaml | ./mustache | kubectl create -f-


