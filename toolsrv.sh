#!/bin/sh

docker pull ndslabs/toolserver:0.9.2 
docker tag ndslabs/toolserver:0.9.2 ncsa/clowder-toolserver
docker run -d -p 8082:8082 --name toolserver -e TOOLSERVER_PORT=8082 -v /var/run/docker.sock:/var/run/docker.sock ndslabs/toolserver:0.9.2 toolserver
