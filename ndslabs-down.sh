#!/bin/bash

kubectl delete svc,rc ndslabs-apiserver
kubectl delete svc,rc ndslabs-gui
kubectl delete svc,rc default-http-backend
kubectl delete rc nginx-ilb-rc 
kubectl delete ingress ndslabs-ingress
kubectl delete secret ndslabs-tls-secret
