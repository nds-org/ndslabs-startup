#!/bin/bash


IP_ADDR_MACHINE=$(ifconfig eth0  | grep "inet " | awk '{print $2}')

echo -n "Enter the domain name for this server: "
read domain

DOMAIN=$domain
APISERVER_HOST="www.$domain"
CORS_ORIGIN_ADDR="https://www.$domain"
APISERVER_SECURE="true"
APISERVER_PORT="443"
INGRESS=LoadBalancer


echo -n "Enter the internal IP address for this server [$IP_ADDR_MACHINE] or ENTER to accept the default: "
read internalip
if [ -n "$internalip" ]; then 
    IP_ADDR_MACHINE=$internalip
fi


echo "APISERVER_HOST=$APISERVER_HOST"
echo "APISERVER_PORT=$APISERVER_PORT"
echo "APISERVER_SECURE=$APISERVER_SECURE"
echo "CORS_ORIGIN_ADDR=$CORS_ORIGIN_ADDR"
echo "INGRESS=$INGRESS"
echo "DOMAIN=$DOMAIN"
export APISERVER_HOST
export APISERVER_PORT
export APISERVER_SECURE
export CORS_ORIGIN_ADDR
export INGRESS
export DOMAIN
export IP_ADDR_PUBLIC
export IP_ADDR_MACHINE


kubectl create secret generic ndslabs-tls-secret --from-file=tls.crt=certs/ndslabs.cert --from-file=tls.key=certs/ndslabs.key --namespace=default
#kubectl create -f ndslabs/lambert/loadbalancer.yaml
#kubectl create -f ndslabs/lambert/default-backend.yaml
cat ndslabs/lambert/default-ingress.yaml | ./mustache | kubectl create -f-

cat ndslabs/lambert/gui.yaml | ./mustache | kubectl create -f-
cat ndslabs/lambert/apiserver.yaml | ./mustache | kubectl create -f-

echo "After the services start, you should be able to access the NDSLabs UI via:"
echo "https://www.$DOMAIN"
