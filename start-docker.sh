#!/bin/bash
set -e

unset DYLD_LIBRARY_PATH
unset LD_LIBRARY_PATH
mkdir -p ~/.boot2docker
if [ ! -f ~/.boot2docker/boot2docker.iso ]; then 
    cp /usr/local/share/boot2docker/boot2docker.iso ~/.boot2docker/
fi
boot2docker init
boot2docker up
# Set the DOCKER_HOST, and if needed DOCKER_CERT_PATH
$(boot2docker shellinit)

# set the localhost's /etc/hosts to resolve the vm
# need to do it unconditionally for the sake of the TLS certs
HOSTNAME=$(boot2docker ssh hostname 2>/dev/null)
IP=$(boot2docker ip 2>/dev/null)
HOSTLINE="$IP	$HOSTNAME"
if ! grep -q "^$HOSTLINE" /etc/hosts ; then
	PROMPT="Please enter your User's password to configure your vm's new hostname"
	sudo -p "$PROMPT" sh -c "echo \"$HOSTLINE\" >> /etc/hosts"
fi

docker version

# Leave the user in a shell that is set up just right.
# TODO: leave them in whatever shell they have set?
bash
