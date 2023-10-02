SHELL := /usr/bin/env bash -euo pipefail

# These need to be separate because the lookup behavior for each of them is
# different -- Bedrock needs Major-Minor-Patch, Java just needs Major-Minor
BEDROCK_VERSION ?= 1.20.30
JAVA_VERSION ?= 1.20
edition ?= bedrock

docker:
	docker build \
		--progress plain \
		--build-arg bedrock_version=$(BEDROCK_VERSION) \
		--build-arg java_version=$(JAVA_VERSION) \
		-t ryapric/minecraft-server:$(BEDROCK_VERSION)_$(JAVA_VERSION) \
		.
	docker tag ryapric/minecraft-server:$(BEDROCK_VERSION)_$(JAVA_VERSION) ryapric/minecraft-server:latest
	docker compose run \
		--name minecraft \
		--service-ports \
		--rm \
		-d \
		minecraft $(edition)

vagrant:
	BEDROCK_VERSION=$(BEDROCK_VERSION) \
	JAVA_VERSION=$(JAVA_VERSION) \
	vagrant up $(edition)

aws:
	terraform -chdir=./terraform/aws init -backend-config=backend.tfvars
	terraform -chdir=./terraform/aws apply

local:
	if [[ $(edition) == 'bedrock' ]] ; then \
		version=$(BEDROCK_VERSION) ; \
	else \
		version=$(JAVA_VERSION) ; \
	fi ; \
	./scripts/init.sh bedrock "$${version}" local

stop:
	docker compose down || true
	docker stop minecraft || true
	BEDROCK_VERSION=$(BEDROCK_VERSION) \
	JAVA_VERSION=$(JAVA_VERSION) \
	vagrant destroy -f || true
