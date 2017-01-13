#!/bin/bash

#
# Stop Labs Workbench
#

kubectl delete svc,rc ndslabs-apiserver
kubectl delete svc,rc ndslabs-gui
kubectl delete svc,rc default-http-backend
kubectl delete rc nginx-ilb-rc 
kubectl delete ingress ndslabs-ingress
kubectl delete secret ndslabs-tls-secret

#
# Stop Developer Environment
#
kubectl delete ing cloud9-ingress
kubectl delete svc,rc cloud9

#
# Remove node label
#
kubectl label nodes 127.0.0.1 ndslabs-node-role-
