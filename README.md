Docker for Mac OS X Installer
=============

![Imgur](http://i.imgur.com/3TlXLPt.png)
![Imgur](http://i.imgur.com/1h93XSW.png)


How to build
============

```
$ docker build -t osx-installer osx-installer/
$ docker run --privileged -i -t -name build-osx-installer osx-installer
$ docker cp build-osx-installer:/docker.dmg .
$ docker rm build-osx-installer
```
