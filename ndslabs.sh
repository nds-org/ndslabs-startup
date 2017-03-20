#!/bin/bash

export BINDIR=$HOME/bin
ECHO='echo -e'

# If "down" is passed as the command, stop Labs Workbench
if [ "${1,,}" == "down" ]; then
    $ECHO 'Stopping Labs Workbench core services...'
    $BINDIR/kubectl delete rc,svc ndslabs-webui ndslabs-apiserver ndslabs-etcd > /dev/null

    $ECHO 'Stopping Labs Workbench SMTP server...'
    $BINDIR/kubectl delete rc,svc ndslabs-smtp

    $ECHO 'Stopping Labs Workbench LMA tools...'
    $BINDIR/kubectl delete rc,svc nagios-nrpe

    $ECHO 'Stopping Labs Workbench LoadBalancer...'
    $BINDIR/kubectl delete rc,svc default-http-backend
    $BINDIR/kubectl delete rc nginx-ilb-rc
    $BINDIR/kubectl delete ingress ndslabs-ingress
    $BINDIR/kubectl delete configmap nginx-ingress-conf

    $ECHO 'Deleting Labs Workbench TLS Secret...'
    $BINDIR/kubectl delete secret ndslabs-tls-secret

    # Remove node label
    $BINDIR/kubectl label nodes 127.0.0.1 ndslabs-node-role-

    $ECHO 'All Labs Workbench services stopped!'
    exit 0
fi

# If "apipass" is passed as the command, print the API server Admin Password to stdout
if [ "${1,,}" == "apipass" -o "${1,,}" == "apipasswd" ]; then
    kubectl exec -it `kubectl get pods | grep apiserver | grep Running | awk '{print $1}'` cat /password.txt
    exit 0
fi

#
# By default, start Labs Workbench 
#

$ECHO -n "Enter the domain name for this server [$DOMAIN]: "
read domain
if [ -n "$domain" ]; then
    DOMAIN=$domain
fi

APISERVER_HOST="www.$DOMAIN"
CORS_ORIGIN_ADDR="https://www.$DOMAIN"
APISERVER_SECURE="true"
APISERVER_PORT="443"
INGRESS=LoadBalancer
REQUIRE_APPROVAL="false"

$ECHO -n "Enter the internal IP address for this server [$IP_ADDR_MACHINE]: "
read internalip
if [ -n "$internalip" ]; then 
    IP_ADDR_MACHINE="$internalip"
fi

$ECHO -n "Require account approval? [y/N] "
read requireapproval
if [ -n "$requireapproval" ]; then
    if [ "${requireapproval,,}" == "y" -o "${requireapproval,,}" == "ye" -o "${requireapproval,,}" == "yes" ]; then
        REQUIRE_APPROVAL="true"

        # Prompt for the support email, which will be required to approve accounts
        $ECHO -n "Enter the e-mail address to use for account approval [$SUPPORT_EMAIL]: "
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

# Generate self-signed TLS certs
if [ ! -f "certs/ndslabs.cert" ]; then
   $ECHO "Creating self-signed certificate for $DOMAIN"
   mkdir -p certs
   openssl genrsa 2048 > certs/ndslabs.key
   openssl req -new -x509 -nodes -sha1 -days 3650 -subj "/C=US/ST=IL/L=Champaign/O=NCSA/OU=NDS/CN=*.$DOMAIN" -key "certs/ndslabs.key" -out "certs/ndslabs.cert"
fi

# Create secret from TLS certs
$BINDIR/kubectl create secret generic ndslabs-tls-secret --from-file=tls.crt=certs/ndslabs.cert --from-file=tls.key=certs/ndslabs.key --namespace=default
$BINDIR/kubectl create -f templates/ilb/loadbalancer.yaml
$BINDIR/kubectl create -f templates/ilb/default-backend.yaml
cat templates/ilb/default-ingress.yaml | ./mustache | $BINDIR/kubectl create -f-

# Start SMTP server
$BINDIR/kubectl create -f templates/smtp/smtp.yaml

# Start core services (etcd, api, ui)
$BINDIR/kubectl label nodes 127.0.0.1 ndslabs-node-role=compute
$BINDIR/kubectl create -f templates/core/etcd.yaml
cat templates/core/apiserver.yaml | ./mustache | $BINDIR/kubectl create -f-
cat templates/core/webui.yaml | ./mustache | $BINDIR/kubectl create -f-

# Start NAGIOS Remote Plugin Executor
$BINDIR/kubectl create -f templates/lma/nagios-nrpe-ds.yaml

$ECHO "\nAfter the services start, you should be able to access the NDSLabs UI via:"
$ECHO "https://www.$DOMAIN"
