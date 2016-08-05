#!/bin/bash

#kubectl delete pods,services,rc --all
#kubectl drain 127.0.0.1
#kubectl delete 127.0.0.1

docker stop `docker ps | grep k8s | awk  '{print $1}'`
docker rm `docker ps -a | grep k8s | awk  '{print $1}'`
