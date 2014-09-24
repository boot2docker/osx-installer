#!/bin/bash

# Uninstall Script

if [ -n "$(which boot2docker)" ] ; then
    echo "boot2docker does not exist on your machine!"
    exit 1
fi

echo "Stopping boot2docker processes..."
boot2docker stop && boot2docker delete

echo "Removing boot2docker executable..."
sudo rm /usr/local/bin/boot2docker

echo "Removing boot2docker ISO and socket files..."
rm -rf ~/.boot2docker
rm -rf /usr/local/share/boot2docker

echo "Removing Docker executable..."
sudo rm /usr/local/bin/docker

echo "All Done!"
