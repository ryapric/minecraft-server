SHELL := /usr/bin/env bash -euo pipefail

BEDROCK_VERSION ?= 1.19.40
JAVA_VERSION ?= 1.19.2

docker:
	docker build \
		--build-arg bedrock_version=$(BEDROCK_VERSION) \
		--build-arg java_version=$(JAVA_VERSION) \
		-t ryapric/minecraft-server:$(BEDROCK_VERSION)_$(JAVA_VERSION) \
		.
	docker tag ryapric/minecraft-server:$(BEDROCK_VERSION)_$(JAVA_VERSION) ryapric/minecraft-server:latest
	docker compose run minecraft $(edition)

vagrant:
	BEDROCK_VERSION=$(BEDROCK_VERSION) \
	JAVA_VERSION=$(JAVA_VERSION) \
	vagrant up $(edition)

local:
	if [[ $(edition) == 'bedrock' ]] ; then version=$(BEDROCK_VERSION) ; else version=$(JAVA_VERSION) ; fi
	./scripts/init.sh bedrock "$${version}" local

stop:
	docker compose down || true
	BEDROCK_VERSION=$(BEDROCK_VERSION) \
	JAVA_VERSION=$(JAVA_VERSION) \
	vagrant destroy -f || true
