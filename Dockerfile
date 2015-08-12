FROM debian:wheezy

RUN apt-get update && apt-get -y install \
		autoconf build-essential curl \
		libxml2-dev libssl-dev \
		p7zip-full \
		hfsplus hfsutils hfsprogs cpio

# We need the bomutils to create the Mac OS X Bill of Materials (BOM) files.
# https://github.com/hogliux/bomutils
RUN curl -fsSL https://github.com/hogliux/bomutils/archive/0.2.tar.gz | tar xvz && \
	cd bomutils-* && \
	make && make install

# Needed to pack/unpack the .pkg files
RUN curl -fsSL https://github.com/mackyle/xar/archive/xar-1.6.1.tar.gz | tar xvz && \
	cd xar-*/xar && \
	./autogen.sh && ./configure && \
	make && make install

ENV VBOX_VERSION 5.0.0
ENV VBOX_REV 101573

RUN curl -fsSL -o /vbox.dmg http://download.virtualbox.org/virtualbox/$VBOX_VERSION/VirtualBox-$VBOX_VERSION-$VBOX_REV-OSX.dmg \
	&& echo "$(curl -fsSL 'http://download.virtualbox.org/virtualbox/'"$VBOX_VERSION"'/SHA256SUMS' | awk '$2 ~ /-OSX.dmg$/ { print $1 }') */vbox.dmg" | sha256sum -c -

# Download the Docker parts

ENV DOCKER_VERSION 1.8.0
RUN curl -fsSL -o /docker.tgz https://get.docker.com/builds/Darwin/x86_64/docker-$DOCKER_VERSION.tgz

ENV BOOT2DOCKER_CLI_VERSION ${DOCKER_VERSION}
RUN curl -fsSL -o /boot2docker https://github.com/boot2docker/boot2docker-cli/releases/download/v${BOOT2DOCKER_CLI_VERSION}/boot2docker-v${BOOT2DOCKER_CLI_VERSION}-darwin-amd64

ENV BOOT2DOCKER_ISO_VERSION $DOCKER_VERSION
RUN curl -fsSL -o /boot2docker.iso https://github.com/boot2docker/boot2docker/releases/download/v${BOOT2DOCKER_ISO_VERSION}/boot2docker.iso

ENV INSTALLER_VERSION $DOCKER_VERSION

# Start building package

COPY mpkg /mpkg

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
	mkdir rootfs && \
	cd rootfs && \
	tar xvzf /docker.tgz && \
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

COPY makedmg.sh /

CMD ["/makedmg.sh", "docker.dmg", "Docker", "/dmg"]
