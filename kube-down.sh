#!/bin/bash

# Remove kubelet first, or else it will continue to respawn killed containers
#docker stop kubelet
docker rm -f kubelet

# Use at your own risk: stop and remove all Docker containers
#docker stop `docker ps | grep gcr | awk  '{print $1}'`
docker rm -f `docker ps -a | grep gcr | awk  '{print $1}'`
