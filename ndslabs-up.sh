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

cat ndslabs/gui.yaml | ./mustache  kubectl create -f-
cat ndslabs/apiserver.yaml | ./mustache kubectl create -f-
