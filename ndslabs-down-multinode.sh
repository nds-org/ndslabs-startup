#!/bin/bash

kubectl delete svc,rc ndslabs-apiserver
kubectl delete svc,rc ndslabs-gui
kubectl delete ingress ndslabs-ingress
kubectl delete secret ndslabs-tls-secret
