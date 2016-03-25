#!/bin/bash

for image in `cat images.txt`
do
    docker pull $image
done
