#!/bin/bash

export BINDIR="$HOME/bin"
ECHO='echo -e'

# Helper function to start all Labs Workbench services
# $1 == seconds to wait between probe attempts
# $@ == all other args of parent are passed in (if "--api-only" is present, we skip starting the ui)
function start_all() {
    # Ensure that Kubernetes is running
    ./kube.sh

    $BINDIR/kubectl create -f templates/config.yaml >/dev/null 2>&1

    # Grab our DOMAIN from the configmap
    DOMAIN="$(cat templates/config.yaml | grep domain | awk '{print $2}' | sed s/\"//g)"
    $ECHO "Starting Labs Workbench:"
    $ECHO "    DOMAIN=$DOMAIN"

    # Generate self-signed TLS certs
    if [ ! -f "certs/${DOMAIN}.cert" ]; then
       $ECHO "\nGenerating self-signed certificate for $DOMAIN"
       mkdir -p certs && \
       openssl genrsa 2048 > certs/${DOMAIN}.key && \
       openssl req -new -x509 -nodes -sha1 -days 3650 -subj "/C=US/ST=IL/L=Champaign/O=NCSA/OU=NDS/CN=*.$DOMAIN" -key "certs/${DOMAIN}.key" -out "certs/${DOMAIN}.cert"
    fi

    # Create secret from TLS certs
    $ECHO '\nGenerating Labs Workbench TLS Secret...'
    $BINDIR/kubectl create secret generic ndslabs-tls-secret --from-file=tls.crt="certs/${DOMAIN}.cert" --from-file=tls.key="certs/${DOMAIN}.key" --namespace=default
    $BINDIR/kubectl create secret generic ndslabs-tls-secret --from-file=tls.crt="certs/${DOMAIN}.cert" --from-file=tls.key="certs/${DOMAIN}.key" --namespace=kube-system

    $ECHO '\nStarting Labs Workbench core services...'
    # Pre-process jinja-style variables by piping through sed
    cat templates/core/loadbalancer.yaml | sed -e "s#{{\s*DOMAIN\s*}}#$DOMAIN#g" | kubectl create -f -
    $BINDIR/kubectl create -f templates/smtp/ -f templates/core/svc.yaml -f templates/core/etcd.yaml -f templates/core/apiserver.yaml

    # Label this as compute node, so that the ndslabs-apiserver can schedule pods here
    $BINDIR/kubectl label nodes 127.0.0.1 ndslabs-role-compute=true
    
    
    # Don't start the webui if we were given --api-only
    if [[ "${@/--api-only/ }" == "$@" ]]; then
        $ECHO '\nStarting Labs Workbench UI...'
        $BINDIR/kubectl create -f templates/core/webui.yaml
    fi

    # TODO: Add support/options for LMA stuff
    # $ECHO '\nStarting Labs Workbench LMA tools...'
    # $BINDIR/kubectl create -f templates/lma/nagios-nrpe-ds.yaml

    # Wait for the API server to start
    $ECHO '\nWaiting for Labs Workbench API server to start...'
    until $(curl --output /dev/null --silent --fail --header "Host: www.$DOMAIN" localhost/api/); do
        $ECHO "Trying again in ${1} seconds..."
        sleep ${1}s # wait before checking again
    done
    $ECHO 'Labs Workbench API server successfully started!'

    if [[ "${@/--api-only/ }" == "$@" ]]; then
        # Wait for the UI server to start
        $ECHO '\nWaiting for Labs Workbench UI server to start...'
        $ECHO '(NOTE: This can take a couple of minutes)'
        until $(curl --output /dev/null --silent --fail --header "Host: www.$DOMAIN" localhost/); do
            $ECHO "Trying again in ${1} seconds..."
            sleep ${1}s # wait before checking again
        done
        $ECHO 'Labs Workbench UI successfully started!'
        $ECHO "\nYou should now be able to access the Labs Workbench UI via:"
        $ECHO "https://www.$DOMAIN"
    fi
}

# Helper function to stop all Labs Workbench services
#   - takes no parameters
function stop_all() {
    # TODO: Add support/options for LMA stuff
    # $ECHO 'Stopping Labs Workbench LMA tools...'
    # $BINDIR/kubectl delete ds --namespace=kube-system nagios-nrpe >/dev/null 2>&1

    $ECHO 'Stopping Labs Workbench UI and API'
    $BINDIR/kubectl delete rc,svc ndslabs-webui ndslabs-apiserver >/dev/null 2>&1

    $ECHO 'Stopping Labs Workbench core services...'
    $BINDIR/kubectl delete rc,svc ndslabs-etcd ndslabs-smtp default-http-backend >/dev/null 2>&1
    $BINDIR/kubectl delete rc nginx-ilb-rc >/dev/null 2>&1
    $BINDIR/kubectl delete ingress ndslabs-ingress  >/dev/null 2>&1
    $BINDIR/kubectl delete configmap nginx-ingress-conf >/dev/null 2>&1

    $ECHO 'Deleting Labs Workbench TLS Secret...'
    $BINDIR/kubectl delete secret ndslabs-tls-secret --namespace=default >/dev/null 2>&1
    $BINDIR/kubectl delete secret ndslabs-tls-secret --namespace=kube-system >/dev/null 2>&1

    # Remove node label
    $BINDIR/kubectl label nodes 127.0.0.1 ndslabs-role-compute- >/dev/null 2>&1

    # Remove Workbench ConfigMap
    $BINDIR/kubectl delete configmap ndslabs-config >/dev/null 2>&1

    $ECHO 'All Labs Workbench services stopped!'
}

if [ "${1,,}" == "apipass" -o "${1,,}" == "apipasswd" ]; then
    # If "apipass" or "apipasswd" is passed as the command, print the API server Admin Password to stdout
    kubectl exec -it `kubectl get pods | grep apiserver | grep Running | awk '{print $1}'` cat /password.txt
elif [ "${1,,}" == "down" ]; then
    # If "down" is passed as the command, stop Labs Workbench
    stop_all
else
    # By default and for all other command, start Labs Workbench
    start_all   "15"    $@
fi

exit 0
