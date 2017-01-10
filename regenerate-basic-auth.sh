#!/bin/bash

kubectl delete secret basic-auth -o name

echo "Enter your desired username for basic auth: "
read username

docker run --rm -ti crosbymichael/htpasswd $username && echo "" && echo "Copy the above line to a file named auth, then execute: " && echo "kubectl create secret generic basic-auth --from-file=./auth" && echo ""
