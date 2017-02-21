#!/bin/sh

export K8S_VERSION=1.5.1

#
# Download kubectl
#
if [ -z ~/bin/kubectl ]; then
   echo "Downloading kubectl binary to ~/bin..."
   mkdir -p ~/bin
   curl http://storage.googleapis.com/kubernetes-release/release/v${K8S_VERSION}/bin/linux/amd64/kubectl -o ~/bin/kubectl
   chmod +x ~/bin/kubectl
fi

#
# Start Kubernetes via Docker
#
echo ''
echo 'Starting Hyperkube Kubelet...'
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
    || (echo '' && echo 'Starting previous Kubelet...' && docker start kubelet)) && echo 'Kubelet started successfully!'
echo ''
echo 'Kubernetes is starting!'
