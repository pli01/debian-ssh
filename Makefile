all: test

PARENT_NAME=$(shell sed -r -n '/^FROM/ {s/^FROM +//;p}' Dockerfile)
PROJECT=debian-ssh
CONTAINER_NAME=$(PROJECT):$(shell git rev-parse --abbrev-ref HEAD | sed 's/master/latest/')
PORT=2222
DOCKER_USER ?= docker

distribute: .FORCE
	for b in $$(git branch --no-merged); do git merge-into $$b --no-edit; done

killall: .FORCE
	docker rm -f -v $$(docker ps | sed -r -n '/^[^ ]+ +$(CONTAINER_NAME) / {s/ .*$$//;p}')

pull: .FORCE
	docker pull $(PARENT_NAME)

build: .FORCE
	docker build  --build-arg  USER=$(DOCKER_USER) -t $(CONTAINER_NAME) .

rebuild: pull .FORCE
	docker build --no-cache -t $(CONTAINER_NAME) .

test: build .FORCE
	docker run -d -p $(PORT):22 -e SSH_KEY="$$(cat ~/.ssh/id_rsa.pub)" $(CONTAINER_NAME)
	while ! ssh $(DOCKER_USER)@localhost -p $(PORT) -o "StrictHostKeyChecking=no" env; do sleep 0.1; done
	docker rm -f -v $$(docker ps -ql)

debug-ssh: build .FORCE
	docker run -p $(PORT):22 -e SSH_KEY="$$(cat ~/.ssh/id_rsa.pub)" $(CONTAINER_NAME)

debug-connect: .FORCE
	ssh $(DOCKER_USER)@localhost -p $(PORT) -o "StrictHostKeyChecking=no" env

debug-connect-root: .FORCE
	ssh root@localhost -p $(PORT) -o "StrictHostKeyChecking=no" env

debug-bash: build .FORCE
	docker run -ti -u $(DOCKER_USER) $(CONTAINER_NAME) bash

debug-bash-root: build .FORCE
	docker run -ti $(CONTAINER_NAME) bash

.FORCE:
