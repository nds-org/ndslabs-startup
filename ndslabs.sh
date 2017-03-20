#!/bin/bash

export BINDIR=$HOME/bin
ECHO='echo -e'

# If "down" is passed as the command, stop Labs Workbench
if [ "${1,,}" == "down" ]; then
    $ECHO 'Stopping Labs Workbench LMA tools...'
    $BINDIR/kubectl delete -f templates/lma/nagios-nrpe-ds.yaml >/dev/null 2>&1

    $ECHO 'Stopping Labs Workbench core services...'
    $BINDIR/kubectl delete rc,svc ndslabs-webui ndslabs-apiserver ndslabs-etcd >/dev/null 2>&1

    $ECHO 'Stopping Labs Workbench SMTP server...'
    $BINDIR/kubectl delete rc,svc ndslabs-smtp >/dev/null 2>&1

    $ECHO 'Stopping Labs Workbench LoadBalancer...'
    $BINDIR/kubectl delete rc,svc default-http-backend >/dev/null 2>&1
    $BINDIR/kubectl delete rc nginx-ilb-rc >/dev/null 2>&1
    $BINDIR/kubectl delete ingress ndslabs-ingress  >/dev/null 2>&1
    $BINDIR/kubectl delete configmap nginx-ingress-conf >/dev/null 2>&1

    $ECHO 'Deleting Labs Workbench TLS Secret...'
    $BINDIR/kubectl delete secret ndslabs-tls-secret --namespace=default >/dev/null 2>&1
    $BINDIR/kubectl delete secret ndslabs-tls-secret --namespace=kube-system >/dev/null 2>&1

    # Remove node label
    $BINDIR/kubectl label nodes 127.0.0.1 ndslabs-node-role- >/dev/null 2>&1

    # Remove Workbench ConfigMap
    $BINDIR/kubectl delete configmap ndslabs-config >/dev/null 2>&1

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

$BINDIR/kubectl create -f templates/config.yaml >/dev/null 2>&1

export DOMAIN="$(cat templates/config.yaml | grep domain | awk '{print $2}' | sed s/\"//g)"
$ECHO "Starting Labs Workbench with DOMAIN=$DOMAIN"

# Generate self-signed TLS certs
if [ ! -f "certs/ndslabs.cert" ]; then
   $ECHO "\nGenerating self-signed certificate for $DOMAIN"
   mkdir -p certs
   openssl genrsa 2048 > certs/ndslabs.key
   openssl req -new -x509 -nodes -sha1 -days 3650 -subj "/C=US/ST=IL/L=Champaign/O=NCSA/OU=NDS/CN=*.$DOMAIN" -key "certs/ndslabs.key" -out "certs/ndslabs.cert"
fi

# Create secret from TLS certs
$ECHO '\nGenerating Labs Workbench TLS Secret...'
$BINDIR/kubectl create secret generic ndslabs-tls-secret --from-file=tls.crt=certs/ndslabs.cert --from-file=tls.key=certs/ndslabs.key --namespace=default
$BINDIR/kubectl create secret generic ndslabs-tls-secret --from-file=tls.crt=certs/ndslabs.cert --from-file=tls.key=certs/ndslabs.key --namespace=kube-system

$ECHO '\nStarting Labs Workbench LoadBalancer...'
$BINDIR/kubectl create -f templates/ilb/loadbalancer.yaml
$BINDIR/kubectl create -f templates/ilb/default-backend.yaml

# FIXME: We still need mustache here.. ingress "hosts" cannot be set via secret or configmap
cat templates/ilb/default-ingress.yaml | ./mustache | $BINDIR/kubectl create -f-

# Start SMTP server
$ECHO '\nStarting Labs Workbench SMTP server...'
$BINDIR/kubectl create -f templates/smtp/smtp.yaml

# Start core services (etcd, api, ui)
$ECHO '\nStarting Labs Workbench core services...'
$BINDIR/kubectl label nodes 127.0.0.1 ndslabs-node-role=compute
$BINDIR/kubectl create -f templates/core/

# Start NAGIOS Remote Plugin Executor
$ECHO '\nStarting Labs Workbench LMA tools...'
$BINDIR/kubectl create -f templates/lma/nagios-nrpe-ds.yaml

# Wait for the API server to start
$ECHO 'Waiting for Labs Workbench API server to start...'
until $(curl --output /dev/null --silent --fail --header "Host: www.${DOMAIN}" localhost/api/); do
  $ECHO 'Trying again in 5 seconds...'
  sleep 5s # wait for 5s before checking again
done

$ECHO 'Labs Workbench API server successfully started!'

# Wait for the UI server to start
$ECHO 'Waiting for Labs Workbench UI server to start...'
until $(curl --output /dev/null --silent --fail --header "Host: www.${DOMAIN}" localhost/index.html); do
  $ECHO 'Trying again in 5 seconds...'
  sleep 5s # wait for 5s before checking again
done

$ECHO 'Labs Workbench UI successfully started!'
$ECHO "\nYou should now be able to access the Labs Workbench UI via:"
$ECHO "https://www.$DOMAIN"
