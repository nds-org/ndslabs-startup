#!/bin/bash

echo -n "Enter the domain name for this server [$DOMAIN]: "
read domain
if [ -n "$domain" ]; then
    DOMAIN=$domain
fi

export DOMAIN

# Notify user that source should be cloned to the correct location
echo "The developer environment assumes that you have the ndslabs source code checked out at /home/core/ndslabs"
echo "If your path differs, you can manually alter the templates for cloud9 and the webui"

# Stop Prod version of webui
kubectl delete svc,rc ndslabs-webui

# Start Dev version of webui and a cloud9 container
cat templates/webui-dev.yaml | ./mustache | kubectl create -f-
cat templates/cloud9.yaml | ./mustache | kubectl create -f-

echo "After the developer environment starts, you should be able to access Cloud9 via:"
echo "https://cloud9.$DOMAIN"
echo ""

echo "If you have a basic-auth secret, those credentials will be required to authenticate into the developer environment"
