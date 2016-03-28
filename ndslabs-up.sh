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

echo -n "Enter the public IP address for this server [$IP_ADDR_PUBLIC] or ENTER to accept the default:"
read publicip
if [ -n "$publicip" ]; then 
	IP_ADDR_PUBLIC=$publicip
fi

echo -n "Enter the internal IP address for this server [$IP_ADDR_MACHINE] or ENTER to accept the default:"
read internaip
if [ -n "$internaip" ]; then 
	IP_ADDR_MACHINE=$internaip
fi

export IP_ADDR_MACHINE
export IP_ADDR_PUBLIC

echo "Using internal IP: $IP_ADDR_MACHINE"
echo "Using public IP: $IP_ADDR_PUBLIC"

cat ndslabs/gui.yaml | ./mustache | kubectl create -f-
cat ndslabs/apiserver.yaml | ./mustache | kubectl create -f-

echo "After the services start, you should be able to access the NDSLabs UI via:"
echo "http://$IP_ADDR_PUBLIC:30000"

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

echo "Creating ~/.ndslabsctl.yaml"
APISERVER=`kubectl describe svc ndslabs-apiserver | grep ^IP | awk '{print $2}'`
echo "server: http://$APISERVER:8083" > ~/.ndslabsctl.yaml
