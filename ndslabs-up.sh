#!/bin/bash

#
# Start Labs Workbench 
#

IP_ADDR_MACHINE=$(ifconfig eth0  | grep "inet " | awk '{print $2}')

echo -n "Enter the domain name for this server: "
read domain

DOMAIN=$domain
APISERVER_HOST="www.$domain"
CORS_ORIGIN_ADDR="https://www.$domain"
APISERVER_SECURE="true"
APISERVER_PORT="443"
INGRESS=LoadBalancer
SUPPORT_EMAIL="your@email.com"
REQUIRE_APPROVAL="false"

echo -n "Enter the internal IP address for this server [$IP_ADDR_MACHINE]: "
read internalip
if [ -n "$internalip" ]; then 
    IP_ADDR_MACHINE="$internalip"
fi

echo -n "Require account approval? [y/N] "
read requireapproval
if [ -n "$requireapproval" ]; then
    if [[ "${requireapproval,,}" == "y" || "${requireapproval,,}" == "ye" || "${requireapproval,,}" == "yes" ]]; then
        REQUIRE_APPROVAL="true"

        # Prompt for the support email, which will be required to approve accounts
        echo -n "Enter the e-mail address to use for account approval [$SUPPORT_EMAIL]: "
        read supportemail
        if [ -n "$supportemail" ]; then
            SUPPORT_EMAIL="$supportemail"
        fi
    else
        REQUIRE_APPROVAL="false"
    fi
fi

echo "APISERVER_HOST=$APISERVER_HOST"
echo "APISERVER_PORT=$APISERVER_PORT"
echo "APISERVER_SECURE=$APISERVER_SECURE"
echo "CORS_ORIGIN_ADDR=$CORS_ORIGIN_ADDR"
echo "INGRESS=$INGRESS"
echo "DOMAIN=$DOMAIN"
echo "SUPPORT_EMAIL=$SUPPORT_EMAIL"
echo "REQUIRE_APPROVAL=$REQUIRE_APPROVAL"
export APISERVER_HOST
export APISERVER_PORT
export APISERVER_SECURE
export CORS_ORIGIN_ADDR
export INGRESS
export DOMAIN
export IP_ADDR_PUBLIC
export IP_ADDR_MACHINE
export SUPPORT_EMAIL
export REQUIRE_APPROVAL


if [ ! -f "certs/ndslabs.cert" ]; then
   echo "Creating self-signed certificate for $DOMAIN"
   mkdir -p certs
   openssl genrsa 2048 > certs/ndslabs.key
   openssl req -new -x509 -nodes -sha1 -days 3650 -subj "/C=US/ST=IL/L=Champaign/O=NCSA/OU=NDS/CN=*.$DOMAIN" -key "certs/ndslabs.key" -out "certs/ndslabs.cert"
fi

kubectl create secret generic ndslabs-tls-secret --from-file=tls.crt=certs/ndslabs.cert --from-file=tls.key=certs/ndslabs.key --namespace=default
kubectl create -f templates/loadbalancer.yaml
kubectl create -f templates/default-backend.yaml
cat templates/default-ingress.yaml | ./mustache | kubectl create -f-
kubectl label nodes 127.0.0.1 ndslabs-node-role=compute

DEVENV=""
echo -n "Start a development environment? [y/N] "
read startdev
if [[ "${startdev,,}" == "y" || "${startdev,,}" == "ye" || "${startdev,,}" == "yes" ]]; then
    DEVENV="ui"
    cat templates/webui-dev.yaml | ./mustache | kubectl create -f-
    cat templates/cloud9.yaml | ./mustache | kubectl create -f-
else
    cat templates/webui.yaml | ./mustache | kubectl create -f-
fi

cat templates/apiserver.yaml | ./mustache | kubectl create -f-

echo "After the services start, you should be able to access the NDSLabs UI via:"
echo "https://www.$DOMAIN"

if [ "$DEVENV" != "" ]; then
    echo "The developer environment assumes that you have the ndslabs source code checked out at /home/core/ndslabs"
    echo "If your location differs, you can manually alter the templates for cloud9 and the webui"
    echo ""

    echo "After the developer environment starts, you should be able to access Cloud9 via:"
    echo "https://cloud9.$DOMAIN"
    echo ""

    echo "If you have a basic-auth secret, those credentials will be required to authenticate into the developer environment"
fi
