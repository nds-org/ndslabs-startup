#!/bin/sh

export K8S_VERSION=1.5.1
export BINDIR="$HOME/bin"
ECHO='echo -e'

# If "down" is given as the command, shut down hyperkube
if [ "${1,,}" == "down" ]; then
    # Remove kubelet first, or else it will continue to respawn killed containers
    $ECHO 'Stopping Kubelet...'
    docker stop kubelet >/dev/null 2>&1
 
    # Use at your own risk: stop and remove all k8s Docker containers
    $ECHO 'Cleaning up leftover Kubernetes resources... (your containers will not be harmed)'
    docker rm -f $(docker ps -a | grep "gcr.io" | awk  '{print $1}') >/dev/null 2>&1 
    $ECHO 'Kubernetes has been shutdown!'

    exit 0
fi

# If "basic-auth" is passed as a command, regenerate the user's basic-auth secret 
if [ "${1,,}" == "basic-auth" ]; then
    kube_output="$($BINDIR/kubectl get secret -o name basic-auth 2>&1)"
    if [ "$kube_output" == "secret/basic-auth" ]; then
        read -p 'Secret "basic-auth" exists. Regenerate it? [y/N] ' regenerate
        if [ "${regenerate:0:1}" == "y" -o "${regenerate:0:1}" == "Y" ]; then
            $BINDIR/kubectl delete secret basic-auth
        else
            exit 1
        fi
    fi


    read -p "Username: " username
    if [ ! -n "$username" ]; then
        $ECHO 'No username entered... Aborting'
        exit 1
    fi

    read -s -p "Password: " password
    if [ ! -n "$password" ]; then
        $ECHO 'No password entered... Aborting'
        exit 1
    fi
    $ECHO ""

    read -s -p "Confirm password: " password_confirm
    if [ ! -n "$password_confirm" -o "$password" != "$password_confirm" ]; then
        $ECHO 'Passwords did not match.'
        exit 1
    fi
    $ECHO ""

    # Duplicate stdout
    auth="$(docker run -it --rm bodom0015/htpasswd -b -c /dev/stdout $username $password | tail -1)" 
    $BINDIR/kubectl create secret generic basic-auth --from-literal=auth="$auth" 
    
 
    exit 0
fi

# If "deploy-tools" is passed as a command, start a container to remotely deploy Labs Workbench using Ansible
# DEPRECATED: This will go away as we move toward kargo
if [ "${1,,}" == "deploy-tools" ]; then
    docker run -it --name deploy-tools -v `pwd`/deploy-tools:/root/SAVED_AND_SENSITIVE_VOLUME ndslabs/deploy-tools:latest bash

    exit 0
fi


#
# By default, start Kubernetes via Hyperkube
#
$ECHO 'Starting Hyperkube Kubelet...'
(docker run \
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
