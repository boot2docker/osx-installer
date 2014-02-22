# This is important since >lucid doesn't have xar
FROM ubuntu:lucid
MAINTAINER Steeve Morin "steeve.morin@gmail.com"

ENV DOCKER_VERSION  0.8.1

# make sure the package repository is up to date
RUN echo "deb http://archive.ubuntu.com/ubuntu lucid main universe multiverse" > /etc/apt/sources.list
RUN apt-get update


RUN apt-get -y install  curl \
                        xar \
                        dmg2img \
                        hfsplus hfsutils hfsprogs \
                        build-essential


# We need the bomutils to create the Mac OS X Bill of Materials (BOM) files.
RUN curl -L https://github.com/steeve/bomutils/archive/master.tar.gz | tar xvz && \
    cd /bomutils-master && \
    make && make install

ADD mpkg /mpkg

# docker.pkg
RUN cd /mpkg/docker.pkg && \
    mkdir ./rootfs && \
    cd rootfs && \
    curl -L http://get.docker.io/builds/Darwin/x86_64/docker-$DOCKER_VERSION.tgz | tar xvz && \
    find . | cpio -o --format odc | gzip -c > ../Payload && \
    mkbom . ../Bom && \
    sed -i \
        -e "s/%DOCKER_NUMBER_OF_FILES%/`find . | wc -l`/g" \
        -e "s/%DOCKER_INSTALL_KBYTES%/`du -sk | cut -f1`/g" \
        -e "s/%DOCKER_VERSION%/$DOCKER_VERSION/g" \
        ../PackageInfo /mpkg/Distribution && \
    cd .. && \
    rm -rf ./rootfs

# Repackage back. Yes, --compression=none is mandatory.
# or this won't install in OSX.
RUN cd /mpkg && \
    xar -c --compression=none -f ../Docker.pkg .
