SHELL := /usr/bin/env bash -euo pipefail

BEDROCK_VERSION := 1.19.40
JAVA_VERSION := 1.19.2

build-docker:
	docker build \
		--build-arg bedrock_version=$(BEDROCK_VERSION) \
		--build-arg java_version=$(JAVA_VERSION) \
		-t ryapric/minecraft-server:$(BEDROCK_VERSION)_$(JAVA_VERSION) \
		.
