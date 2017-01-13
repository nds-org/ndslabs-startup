#!/bin/sh

kubectl exec -it `kubectl get pods | grep apiserver | grep Running | awk '{print $1}'` cat /password.txt
