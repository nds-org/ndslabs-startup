#!/bin/bash

kubectl delete pods,services,rc --all
kubectl drain 127.0.0.1
kubectl delete 127.0.0.1
