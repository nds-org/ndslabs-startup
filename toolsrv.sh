#!/bin/sh

docker run -d -p 8082:8082 --name toolserver -e TOOLSERVER_PORT=8082 -v /var/run/docker.sock:/var/run/docker.sock ndslabs/toolserver:terra toolserver
