#!/bin/bash

# Use at your own risk: stop and remove all Docker containers
docker stop `docker ps | grep gcr | awk  '{print $1}'`
docker rm `docker ps -a | grep gcr | awk  '{print $1}'`
