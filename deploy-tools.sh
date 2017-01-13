#!/usr/bin/bash

# Simple command to run the deploy-tools container
docker run -it --name deploy-tools -v `pwd`/deploy-tools:/root/SAVED_AND_SENSITIVE_VOLUME ndslabs/deploy-tools:latest bash
