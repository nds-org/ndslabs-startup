#!/bin/bash

# Remove kubelet first, or else it will continue to respawn killed containers
echo 'Stopping Kubelet...'
docker stop kubelet
#docker rm -f kubelet

# Use at your own risk: stop and remove all Docker containers
echo ''
echo 'Killing leftover Kubernetes resources...'
#docker stop `docker ps | grep k8s | awk  '{print $1}'`
docker rm -f `docker ps -a | grep k8s | awk  '{print $1}'`
echo ''
echo 'Kubernetes is now shutdown!'
