#!/bin/bash

b2d="/usr/local/bin/boot2docker"
unset DYLD_LIBRARY_PATH ; unset LD_LIBRARY_PATH
mkdir -p ~/.boot2docker
if [ ! -f ~/.boot2docker/boot2docker.iso ]; then cp /usr/local/share/boot2docker/boot2docker.iso ~/.boot2docker/ ; fi
$b2d ip
$b2d init
$b2d up && export DOCKER_HOST=tcp://$(/usr/local/bin/boot2docker ip 2>/dev/null):2375
docker version