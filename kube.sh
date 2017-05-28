#!/bin/bash

export K8S_VERSION=1.5.1
export BINDIR="$HOME/bin"
ECHO='echo -e'

command="$(echo $1 | tr '[A-Z]' '[a-z]')"

# If "down" is given as the command, shut down hyperkube
if [ "$command" == "down" ]; then
    # Warn user of consequences
    $ECHO 'WARNING: Shutting down Kubernetes will delete all containers running under Kubernetes?'
    $ECHO 'This will DELETE ALL CONTAINER DATA that is not stored on a peristent volume mount.\n'

    # Confirm that user knows what they're doing.
    read -p 'Are you sure you want to continue? [y/N] ' confirm_shutdown
    if [ "${confirm_shutdown:0:1}" != "y" -a "${confirm_shutdown:0:1}" != "Y" ]; then
        exit 1
    fi

    # Remove kubelet first, or else it will continue to respawn killed containers
    $ECHO 'Stopping Kubelet...'
    docker stop kubelet >/dev/null 2>&1

    # Use at your own risk: stop and remove all k8s Docker containers
    $ECHO 'Cleaning up leftover Kubernetes resources...'
    docker rm -f $(docker ps -a | grep k8s | awk  '{print $1}') >/dev/null 2>&1
    $ECHO 'Kubernetes has been shutdown!'

    exit 0
fi

# If "deploy-tools" is passed as a command, start a container to remotely deploy Labs Workbench using Ansible
# DEPRECATED: This will go away as we move toward kargo
if [ "$command" == "deploy-tools" ]; then
    docker run -it --name deploy-tools -v `pwd`/deploy-tools:/root/SAVED_AND_SENSITIVE_VOLUME ndslabs/deploy-tools:latest bash

    exit 0
fi


#
# By default, start Kubernetes via Hyperkube
#
$ECHO 'Starting Hyperkube Kubelet...'
docker --version >/dev/null 2>&1 || ($ECHO 'Docker must be installed to run Kubernetes Hyperkube. If you prefer to use minikube, please run minikube command.' && exit 1)
(docker run \
	--restart=always \
    --volume=/:/rootfs:ro \
    --volume=/sys:/sys:ro \
    --volume=/var/lib/docker/:/var/lib/docker:rw \
    --volume=/var/lib/kubelet/:/var/lib/kubelet:rw,rslave \
    --volume=/var/run:/var/run:rw \
    --volume=`pwd`/manifests:/etc/kubernetes/manifests \
    --net=host \
    --pid=host \
    --privileged=true \
    --name=kubelet \
    -d \
    gcr.io/google_containers/hyperkube-amd64:v${K8S_VERSION} \
    /hyperkube kubelet \
        --containerized \
        --hostname-override="127.0.0.1" \
        --address="0.0.0.0" \
        --api-servers=http://localhost:8080 \
        --config=/etc/kubernetes/manifests \
	--allow-privileged=true --v=2 \
        >/dev/null 2>&1 \
    || docker start kubelet >/dev/null 2>&1)
$ECHO 'Waiting for Kubernetes API server to start on port 8080...'

#
# Download kubectl, if necessary
#
if [ ! -d "$BINDIR" ]; then
    mkdir -p $BINDIR
    $ECHO "Downloading kubectl binary to $BINDIR..."
    curl http://storage.googleapis.com/kubernetes-release/release/v${K8S_VERSION}/bin/linux/amd64/kubectl -o ~/bin/kubectl
    chmod +x ~/bin/kubectl

    # TODO: Need an elegant way to add bins to PATH programmatically
    export PATH="$BINDIR:$PATH"
    $ECHO "Be sure to execute 'export PATH=$BINDIR:\$PATH' to add the directory contaning kubectl to your PATH."
fi

# Wait for Kubernetes to start
until $(curl --output /dev/null --silent --head --fail http://localhost:8080); do   
  $ECHO 'Trying again in 5 seconds...'
  sleep 5s # wait for 5s before checking again
  kube_output=$($BINDIR/kubectl get pods)
done

$ECHO 'Kubernetes has started!'
$ECHO 'You can access your cluster using the kubectl binary.'
