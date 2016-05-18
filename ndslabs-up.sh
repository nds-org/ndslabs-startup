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
if [ -n "$domain" ]; then 
	DOMAIN=$domain
fi

if [ -z $DOMAIN ]; then
   echo -n "Enter the public IP address for this server [$IP_ADDR_PUBLIC] or ENTER to accept the default: "
   read publicip
   if [ -n "$publicip" ]; then 
   	IP_ADDR_PUBLIC=$publicip
   fi
fi

echo -n "Enter the internal IP address for this server [$IP_ADDR_MACHINE] or ENTER to accept the default: "
read internaip
if [ -n "$internaip" ]; then 
	IP_ADDR_MACHINE=$internaip
fi

export IP_ADDR_MACHINE
export IP_ADDR_PUBLIC
export DOMAIN

kubectl create secret generic ndslabs-tls-secret --from-file=tls.crt=certs/ndslabs.cert --from-file=tls.key=certs/ndslabs.key --namespace=default
kubectl create -f ndslabs/loadbalancer.yaml
kubectl create -f ndslabs/default-backend.yaml
cat ndslabs/gui.yaml | ./mustache | kubectl create -f-
cat ndslabs/apiserver.yaml | ./mustache | kubectl create -f-
cat ndslabs/default-ingress.yaml | ./mustache | kubectl create -f-

if [ -n $DOMAIN ]; then 
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
