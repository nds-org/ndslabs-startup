#!/bin/sh

#
# Start Kubernetes via Docker
#
docker run \
    --volume=/:/rootfs:ro \
    --volume=/sys:/sys:ro \
    --volume=/var/lib/docker/:/var/lib/docker:rw \
    --volume=/var/lib/kubelet/:/var/lib/kubelet:rw \
    --volume=/var/run:/var/run:rw \
    --volume=`pwd`/kubernetes/etcd.json:/etc/kubernetes/manifests/etcd.json \
    --net=host \
    --pid=host \
    --privileged=true \
    -d \
    gcr.io/google_containers/hyperkube-amd64:v1.2.0 \
    /hyperkube kubelet \
        --containerized \
        --hostname-override="127.0.0.1" \
        --address="0.0.0.0" \
        --api-servers=http://localhost:8080 \
        --config=/etc/kubernetes/manifests \
	--allow-privileged=true --v=2

mkdir -p ~/bin
if [ ! -e ~/bin/kubectl ]; then
	curl http://storage.googleapis.com/kubernetes-release/release/v1.2.0/bin/linux/amd64/kubectl -o ~/bin/kubectl
	chmod +x ~/bin/kubectl
fi
