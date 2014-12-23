DOCKER_IMAGE := osx-installer
DOCKER_CONTAINER := build-osx-installer

default: dockerbuild
	@true

dockerbuild: clean
	docker build -t $(DOCKER_IMAGE) .
	docker run --privileged -i -t --name "$(DOCKER_CONTAINER)" "$(DOCKER_IMAGE)"
	docker cp "$(DOCKER_CONTAINER)":/dmg/Docker.pkg .

clean:
	rm -f Docker.pkg
	docker rm "$(DOCKER_CONTAINER)" 2>/dev/null || true

