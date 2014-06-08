Docker for Mac OS X Installer
=============

Installation [instructions](http://docs.docker.io/installation/mac/) available on the Docker documentation site.

How to build
============

```
$ docker rm build-osx-installer;true &&\
 docker build -t osx-installer . &&\
 docker run --privileged -i -t -name build-osx-installer osx-installer &&\
 docker cp build-osx-installer:/docker.dmg .
```
