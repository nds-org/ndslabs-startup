#!/bin/bash

export BINDIR="$HOME/bin"
ECHO='echo -e'

#
# Download a copy of linux kubectl, if necessary
#
function download_kubectl() {
  if [ ! -d "$BINDIR" ]; then
      mkdir -p $BINDIR
  fi

  if [ ! -f /$BINDIR/kubectl ]; then
      $ECHO "Downloading kubectl binary to $BINDIR..."
      curl http://storage.googleapis.com/kubernetes-release/release/v${K8S_VERSION}/bin/linux/amd64/kubectl -o ~/bin/kubectl
      chmod +x ~/bin/kubectl

      # TODO: Need an elegant way to add bins to PATH programmatically
      export PATH="$BINDIR:$PATH"
      $ECHO "Be sure to execute 'export PATH=$BINDIR:\$PATH' to add the directory contaning kubectl to your PATH."
  fi
}

# Determine if kubectl is already installed. If not, download a copy
export KUBECTL_BIN=$(which kubectl)
if [ "$KUBECTL_BIN" == "" ]; then
  download_kubectl
  export KUBECTL_BIN="$BINDIR/kubectl"
fi
echo "KUBECTL $KUBECTL_BIN"

# Helper function to start all Labs Workbench services
# $1 == seconds to wait between probe attempts
# $2 == Flag whether to start the UI too
# $3 == Flag whether to start our own bind service
function start_all() {
  # Ensure that Kubernetes is running
  $KUBECTL_BIN apply -f templates/config.yaml >/dev/null 2>&1

  # Grab our DOMAIN from the configmap
  DOMAIN="$(cat templates/config.yaml | grep workbench.domain | awk '{print $2}' | sed s/\"//g)"
  $ECHO "Starting Labs Workbench:"
  $ECHO "    DOMAIN=$DOMAIN"

  # Generate self-signed TLS certs
  if [ ! -f "certs/${DOMAIN}.cert" ]; then
    $ECHO "\nGenerating self-signed certificate for $DOMAIN"
    mkdir -p certs \
      && openssl genrsa 2048 >certs/${DOMAIN}.key \
      && openssl req -new -x509 -nodes -sha1 -days 3650 -subj "/C=US/ST=IL/L=Champaign/O=NCSA/OU=NDS/CN=*.$DOMAIN" -key "certs/${DOMAIN}.key" -out "certs/${DOMAIN}.cert"
  fi

  # Create secret from TLS certs
  $ECHO '\nGenerating Labs Workbench TLS Secret...'
  $KUBECTL_BIN create secret generic ndslabs-tls-secret --from-file=tls.crt="certs/${DOMAIN}.cert" --from-file=tls.key="certs/${DOMAIN}.key" --namespace=default

  $ECHO '\nStarting Labs Workbench core services...'

  # Pre-process jinja-style variables by piping through sed
  cat templates/core/loadbalancer.yaml | sed -e "s#{{[ \s]*DOMAIN[ \s]*}}#$DOMAIN#g" | $KUBECTL_BIN apply -f -
  $KUBECTL_BIN apply -f templates/smtp/ -f templates/core/svc.yaml -f templates/core/etcd.yaml -f templates/core/apiserver.yaml -f templates/core/oauth2-proxy.yaml

  # Only start bind if requested
  if [ "$3" == YES ]; then
    $KUBECTL_BIN apply -f templates/core/bind.yaml
  fi

  # Label this as compute node, so that the ndslabs-apiserver can schedule pods here
  nodename=$($KUBECTL_BIN get nodes | grep -v NAME | awk '{print $1}')
  $KUBECTL_BIN label nodes ${nodename} ndslabs-role-compute=true

  # Don't start the ui if not required by user
  if [ "$2" == YES ]; then
    $ECHO '\nStarting Labs Workbench UI...'
    $KUBECTL_BIN apply -f templates/core/webui.yaml
  fi

  # TODO: Add support/options for LMA stuff
  # $ECHO '\nStarting Labs Workbench LMA tools...'
  # $KUBECTL_BIN apply -f templates/lma/nagios-nrpe-ds.yaml

  # Wait for the API server to start
  $ECHO '\nWaiting for Labs Workbench API server to start...'

  BASE_URL=localhost
  if type "minikube" &>/dev/null && minikube ip ]] &>/dev/null; then
    BASE_URL=https://www.$DOMAIN/
    $ECHO "\nDetected minikube instance, using $BASE_URL (requires /etc/hosts entry)\n"
  fi

  until $(curl -k --output /dev/null --silent --fail --header "Host: www.$DOMAIN" $BASE_URL/api/); do
    $ECHO "Trying again in ${1} seconds..."
    sleep ${1}s # wait before checking again
  done
  $ECHO 'Labs Workbench API server successfully started!'

  if [ "$2" == YES ]; then
    # Wait for the UI server to start
    $ECHO '\nWaiting for Labs Workbench UI server to start...'
    $ECHO '(NOTE: This can take a couple of minutes)'
    until $(curl -k --output /dev/null --silent --fail --header "Host: www.$DOMAIN" $BASE_URL/); do
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
  # $KUBECTL_BIN delete ds --namespace=kube-system nagios-nrpe >/dev/null 2>&1

  $ECHO 'Stopping Labs Workbench UI and API'
  $KUBECTL_BIN delete rc,svc ndslabs-webui ndslabs-apiserver >/dev/null 2>&1

  $ECHO 'Stopping Labs Workbench core services...'
  $KUBECTL_BIN delete rc,svc ndslabs-etcd ndslabs-smtp default-http-backend >/dev/null 2>&1
  $KUBECTL_BIN delete deploy,svc oauth2-proxy >/dev/null 2>&1
  $KUBECTL_BIN delete rc nginx-ilb-rc >/dev/null 2>&1
  $KUBECTL_BIN delete ingress ndslabs-ingress >/dev/null 2>&1
  $KUBECTL_BIN delete configmap nginx-ingress-conf >/dev/null 2>&1

  $ECHO 'Deleting Labs Workbench TLS Secret...'
  $KUBECTL_BIN delete secret ndslabs-tls-secret --namespace=default >/dev/null 2>&1
  $KUBECTL_BIN delete secret ndslabs-tls-secret --namespace=kube-system >/dev/null 2>&1

  # Remove node label
  nodename=$($KUBECTL_BIN get nodes | grep -v NAME | awk '{print $1}')
  $KUBECTL_BIN label nodes ${nodename} ndslabs-role-compute- >/dev/null 2>&1

  # Remove Workbench ConfigMap
  $KUBECTL_BIN delete configmap ndslabs-config >/dev/null 2>&1

  # Stop bind/dns
  $KUBECTL_BIN delete -f templates/core/bind.yaml >/dev/null 2>&1

  $ECHO 'All Labs Workbench services stopped!'
  $ECHO 'Remember to remove any DNS entries if using the Bind service'
}

# Extract the API password from the api password and print to the console
function print_api_password() {
  $KUBECTL_BIN exec -it $($KUBECTL_BIN get pods | grep apiserver | grep Running | awk '{print $1}') cat /password.txt
}

# Default command line options
START_BIND=NO
START_UI=YES

# Parse command line options and requested operation
for i in "$@"; do
  case $i in
    up)
      OPERATION=UP
      shift # past argument with no value
      ;;

    down)
      OPERATION=DOWN
      shift # past argument with no value
      ;;

    print-passwd | apipass | apipasswd)
      OPERATION=PRINT-PASSWORD
      shift # past argument with no value
      ;;

    --no-ui)
      START_UI=NO
      shift # past argument with no value
      ;;

    --start-bind)
      START_BIND=YES
      shift # past argument with no value
      ;;

    *) # unknown option
      echo "Unknown commnad line option: $i"
      exit
      ;;
  esac
done

case $OPERATION in
  PRINT-PASSWORD)
    print_api_password
    ;;

  DOWN)
    stop_all
    ;;

  UP)
    start_all 15 $START_UI $START_BIND
    ;;

  *)
    echo "Usage: ndslabs.sh up|down|print-passwd  [--no-ui] [--start-bind]"
    ;;
esac
exit 0
