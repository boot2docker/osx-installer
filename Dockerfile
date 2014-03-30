FROM ubuntu:12.04
MAINTAINER Steeve Morin "steeve.morin@gmail.com"

ENV DOCKER_VERSION  0.9.1

# make sure the package repository is up to date
RUN echo "deb http://archive.ubuntu.com/ubuntu precise main universe multiverse" > /etc/apt/sources.list
RUN apt-get update


RUN apt-get -y install  curl \
                        build-essential \
                        libxml2-dev libssl-dev \
                        p7zip-full \
                        hfsplus hfsutils hfsprogs


# We need the bomutils to create the Mac OS X Bill of Materials (BOM) files.
RUN curl -L https://github.com/steeve/bomutils/archive/master.tar.gz | tar xvz && \
    cd /bomutils-master && \
    make && make install

# Needed to pack/unpack the .pkg files
RUN curl -L https://github.com/downloads/mackyle/xar/xar-1.6.1.tar.gz | tar xvz && \
    cd xar-1.6.1 && \
    ./configure && \
    make && make install

ADD mpkg /mpkg

# Downloading VirtualBox and extract the .pkg
RUN mkdir -p /mpkg/vbox && \
    cd /mpkg/vbox && \
    curl -L -o vbox.dmg http://download.virtualbox.org/virtualbox/4.3.10/VirtualBox-4.3.10-93012-OSX.dmg && \
    7z x vbox.dmg -ir'!*.hfs' && \
    7z x `find . -name '*.hfs'` -ir'!*.pkg' && \
    mv VirtualBox/VirtualBox.pkg . && \
    rm -rf vbox.dmg && \
    rm -rf `find . -name '*.hfs'`

# Extract the .pkg files
RUN cd /mpkg/vbox && \
    mv VirtualBox.pkg /tmp && \
    xar -xf /tmp/VirtualBox.pkg && \
    rm -rf /tmp/VirtualBox.pkg

RUN cd /mpkg/vbox && \
    mv *.pkg .. && \
    rm -rf vbox

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

# boot2docker.pkg
RUN cd /mpkg/boot2docker.pkg && \
    mkdir ./rootfs && \
    cd ./rootfs && \
    curl -L -o boot2docker https://github.com/boot2docker/boot2docker/raw/master/boot2docker && \
    chmod +x boot2docker && \
    find . | cpio -o --format odc | gzip -c > ../Payload && \
    mkbom . ../Bom && \
    sed -i \
        -e "s/%BOOT2DOCKER_NUMBER_OF_FILES%/`find . | wc -l`/g" \
        -e "s/%BOOT2DOCKER_INSTALL_KBYTES%/`du -sk | cut -f1`/g" \
        -e "s/%BOOT2DOCKER_VERSION%/0.0.1/g" \
        ../PackageInfo /mpkg/Distribution && \
    cd .. && \
    rm -rf ./rootfs

# Make DMG rootfs
RUN mkdir -p /dmg

# Repackage back. Yes, --compression=none is mandatory.
# or this won't install in OSX.
RUN cd /mpkg && \
    xar -c --compression=none -f /dmg/Docker.pkg .

ADD makedmg.sh /
RUN chmod +x makedmg.sh

CMD ["/makedmg.sh", "docker.dmg", "Docker", "/dmg"]
