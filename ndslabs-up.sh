#!/bin/bash


UNAME=$(uname)

if [ "$UNAME" == "Darwin" ]; then
   echo "Assuming docker-machine"
   IP_ADDR_MACHINE=$(docker-machine ip)
   IP_ADDR_PUBLIC=$(docker-machine ip)
elif [ "$UNAME" == "Linux" ]; then
    IP_ADDR_MACHINE=$(ifconfig eth0  | grep "inet " | awk '{print $2}')
    IP_ADDR_PUBLIC=$(curl -s https://api.ipify.org)
fi

echo -n "Enter the domain name for this server or ENTER to not configure: "
read domain

if [ -z "$domain" ]; then
   echo -n "Enter the public IP address for this server [$IP_ADDR_PUBLIC] or ENTER to accept the default: "
   read publicip
   if [ -n "$publicip" ]; then 
      IP_ADDR_PUBLIC=$publicip
   fi
   APISERVER_HOST="$IP_ADDR_PUBLIC"
   APISERVER_PORT="30001"
   APISERVER_SECURE="false"
   CORS_ORIGIN_ADDR="http://$IP_ADDR_PUBLIC:30000"
   INGRESS=NodePort
else
   DOMAIN=$domain
   APISERVER_HOST="www.$domain"
   CORS_ORIGIN_ADDR="https://www.$domain"
   APISERVER_SECURE="true"
   APISERVER_PORT="443"
   INGRESS=LoadBalancer
fi


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


ubectl label nodes 127.0.0.1 ndslabs-role=compute

if [ -n "$DOMAIN" ]; then 
    kubectl create secret generic ndslabs-tls-secret --from-file=tls.crt=certs/ndslabs.cert --from-file=tls.key=certs/ndslabs.key --namespace=default
    kubectl create -f ndslabs/loadbalancer.yaml
    kubectl create -f ndslabs/default-backend.yaml
    cat ndslabs/default-ingress.yaml | ./mustache | kubectl create -f-
fi


cat ndslabs/gui.yaml | ./mustache | kubectl create -f-
cat ndslabs/apiserver.yaml | ./mustache | kubectl create -f-

if [ -n "$DOMAIN" ]; then 
    echo "After the services start, you should be able to access the NDSLabs UI via:"
    echo "https://www.$DOMAIN"
else
    echo "After the services start, you should be able to access the NDSLabs UI via:"
    echo "http://$IP_ADDR_PUBLIC:30000"
fi

mkdir -p ~/bin
if [ ! -e ~/bin/ndslabsctl ]; then
    echo "Downloading ndslabsctl to ~/bin"
    if [ "$UNAME" == "Darwin" ]; then
        curl -sL https://github.com/nds-org/ndslabs/releases/download/v1.0-alpha/ndslabsctl-darwin-amd64 -o ~/bin/ndslabsctl
    elif [ "$UNAME" == "Linux" ]; then
        curl -sL https://github.com/nds-org/ndslabs/releases/download/v1.0-alpha/ndslabsctl-linux-amd64 -o ~/bin/ndslabsctl
    fi
    chmod +x ~/bin/ndslabsctl
fi
