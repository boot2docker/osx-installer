FROM debian:wheezy
MAINTAINER Steeve Morin "steeve.morin@gmail.com"

# make sure the package repository is up to date
RUN apt-get update

RUN apt-get -y install  curl \
                        build-essential \
                        libxml2-dev libssl-dev \
                        p7zip-full \
                        hfsplus hfsutils hfsprogs cpio

# We need the bomutils to create the Mac OS X Bill of Materials (BOM) files.
RUN curl -L https://github.com/steeve/bomutils/archive/master.tar.gz | tar xvz && \
    cd /bomutils-master && \
    make && make install

# Needed to pack/unpack the .pkg files
RUN curl -L https://github.com/downloads/mackyle/xar/xar-1.6.1.tar.gz | tar xvz && \
    cd xar-1.6.1 && \
    ./configure && \
    make && make install

ENV VBOX_VERSION 4.3.14
RUN curl -L -o vbox.dmg http://download.virtualbox.org/virtualbox/$VBOX_VERSION/VirtualBox-$VBOX_VERSION-95030-OSX.dmg

# Download the Docker parts

ENV DOCKER_VERSION  1.2.0
ENV BOOT2DOCKER_CLI_VERSION 1.2.0
ENV BOOT2DOCKER_ISO_VERSION 1.2.0
ENV INSTALLER_VERSION 1.2.0

RUN curl -L -o /docker.tgz http://get.docker.io/builds/Darwin/x86_64/docker-$DOCKER_VERSION.tgz
RUN curl -L -o /boot2docker https://github.com/boot2docker/boot2docker-cli/releases/download/v${BOOT2DOCKER_CLI_VERSION}/boot2docker-v${BOOT2DOCKER_CLI_VERSION}-darwin-amd64
RUN	curl -L -o /boot2docker.iso https://github.com/boot2docker/boot2docker/releases/download/v${BOOT2DOCKER_ISO_VERSION}/boot2docker.iso

# Start building package

ADD mpkg /mpkg

#  Extract the VirtualBox .pkg
RUN mkdir -p /mpkg/vbox && \
    cd /mpkg/vbox && \
    7z x /vbox.dmg -ir'!*.hfs' && \
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
    cat /docker.tgz | tar xvz && \
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
    cp /boot2docker . && \
    chmod +x boot2docker && \
    find . | cpio -o --format odc | gzip -c > ../Payload && \
    mkbom . ../Bom && \
    sed -i \
        -e "s/%BOOT2DOCKER_NUMBER_OF_FILES%/`find . | wc -l`/g" \
        -e "s/%BOOT2DOCKER_INSTALL_KBYTES%/`du -sk | cut -f1`/g" \
        -e "s/%BOOT2DOCKER_VERSION%/$BOOT2DOCKER_CLI_VERSION/g" \
        ../PackageInfo /mpkg/Distribution && \
    cd .. && \
    rm -rf ./rootfs

# boot2dockeriso.pkg
RUN cd /mpkg/boot2dockeriso.pkg && \
    mkdir ./rootfs && \
    cd ./rootfs && \
    cp /boot2docker.iso . && \
    find . | cpio -o --format odc | gzip -c > ../Payload && \
    mkbom . ../Bom && \
    sed -i \
        -e "s/%BOOT2DOCKER_ISO_NUMBER_OF_FILES%/`find . | wc -l`/g" \
        -e "s/%BOOT2DOCKER_ISO_INSTALL_KBYTES%/`du -sk | cut -f1`/g" \
        -e "s/%BOOT2DOCKER_ISO_VERSION%/$BOOT2DOCKER_ISO_VERSION/g" \
        ../PackageInfo /mpkg/Distribution && \
    cd .. && \
    rm -rf ./rootfs

ADD /mpkg/boot2dockerutils.pkg/start.sh /
# boot2dockerutils.pkg
RUN cd /mpkg/boot2dockerutils.pkg && \
    mkdir ./rootfs && \
    cd ./rootfs && \
    cp /start.sh . && \
    chmod +x start.sh && \
    find . | cpio -o --format odc | gzip -c > ../Payload && \
    mkbom . ../Bom && \
    sed -i \
        -e "s/%BOOT2DOCKER_NUMBER_OF_FILES%/`find . | wc -l`/g" \
        -e "s/%BOOT2DOCKER_INSTALL_KBYTES%/`du -sk | cut -f1`/g" \
        -e "s/%BOOT2DOCKER_VERSION%/$BOOT2DOCKER_CLI_VERSION/g" \
        ../PackageInfo /mpkg/Distribution && \
    cd .. && \
    rm -rf ./rootfs

# boot2dockerapp.pkg
RUN cd /mpkg/boot2dockerapp.pkg && \
    mkdir ./rootfs && \
    cd ./rootfs && \
    mv /mpkg/boot2docker.app . && \
    find . | cpio -o --format odc | gzip -c > ../Payload && \
    mkbom . ../Bom && \
    sed -i \
        -e "s/%BOOT2DOCKERAPP_NUMBER_OF_FILES%/`find . | wc -l`/g" \
        -e "s/%BOOT2DOCKERAPP_INSTALL_KBYTES%/`du -sk | cut -f1`/g" \
        -e "s/%BOOT2DOCKERAPP_VERSION%/$INSTALLER_VERSION/g" \
        ../PackageInfo /mpkg/Distribution && \
    cd .. && \
    rm -rf ./rootfs

RUN sed -i \
        -e "s/%INSTALLER_VERSION%/$INSTALLER_VERSION/g" \
        mpkg/Resources/en.lproj/Welcome.html
RUN sed -i \
        -e "s/%INSTALLER_VERSION%/$INSTALLER_VERSION/g" \
        mpkg/Resources/en.lproj/Installed.html
RUN sed -i \
        -e "s/%INSTALLER_VERSION%/$INSTALLER_VERSION/g" \
        /mpkg/Distribution && \
		sed -i \
        -e "s/%VBOX_VERSION%/$VBOX_VERSION/g" \
        /mpkg/Distribution && \
		sed -i \
        -e "s/%VBOX_VERSION%/$VBOX_VERSION/g" \
        mpkg/Resources/en.lproj/Localizable.strings

# Make DMG rootfs
RUN mkdir -p /dmg

# Repackage back. Yes, --compression=none is mandatory.
# or this won't install in OSX.
RUN cd /mpkg && \
    xar -c --compression=none -f /dmg/Docker.pkg .

ADD makedmg.sh /
RUN chmod +x makedmg.sh

CMD ["/makedmg.sh", "docker.dmg", "Docker", "/dmg"]
