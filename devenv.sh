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

if [ "${1,,}" == "down" -o "${1,,}" == "--down" ]; then
    # Stop Dev version of webui and a cloud9 container
    kubectl delete svc,rc ndslabs-webui
    kubectl delete svc,rc cloud9
    kubectl delete ingress cloud9-ingress

    # Start Prod version of webui
    cat templates/core/webui.yaml | ./mustache | kubectl create -f-

    exit 0
fi


# Notify user that source should be cloned to the correct location
echo "The developer environment assumes that you have the ndslabs source code checked out at /home/core/ndslabs"
echo "If your path differs, you can manually alter the templates for cloud9 and the webui"

# Stop Prod version of webui
kubectl delete svc,rc ndslabs-webui

# Start Dev version of webui and a cloud9 container
cat templates/dev/webui.yaml | ./mustache | kubectl create -f-
cat templates/dev/cloud9.yaml | ./mustache | kubectl create -f-

echo "After the developer environment starts, you should be able to access Cloud9 via:"
echo "https://cloud9.$DOMAIN"
echo ""

echo "If you have a basic-auth secret, those credentials will be required to authenticate into the developer environment"
