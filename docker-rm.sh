#!/bin/bash

docker stop `docker ps | awk  '{print $1}' | grep -v CON`
docker rm `docker ps -a | awk  '{print $1}' | grep -v CON`
