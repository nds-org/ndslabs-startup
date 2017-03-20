#!/bin/bash

#
# Stop Labs Workbench
#

echo 'Stopping Labs Workbench core services...'
kubectl delete rc,svc ndslabs-webui ndslabs-apiserver ndslabs-etcd > /dev/null

echo 'Stopping Labs Workbench SMTP server...'
kubectl delete rc,svc ndslabs-smtp > /dev/null

echo 'Stopping Labs Workbench LMA tools...'
kubectl delete rc,svc nagios-nrpe > /dev/null

echo 'Stopping Labs Workbench LoadBalancer...'
kubectl delete rc,svc default-http-backend > /dev/null
kubectl delete rc nginx-ilb-rc > /dev/null
kubectl delete ingress default-ingress > /dev/null

echo 'Deleting Labs Workbench TLS Secret...'
kubectl delete secret ndslabs-tls-secret

#
# Remove node label
#
kubectl label nodes 127.0.0.1 ndslabs-node-role-


echo 'All Labs Workbench services stopped!'

