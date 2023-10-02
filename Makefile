SHELL := /usr/bin/env bash -euo pipefail

# These need to be separate because the lookup behavior for each of them is
# different -- Bedrock needs Major-Minor-Patch, Java just needs Major-Minor
BEDROCK_VERSION ?= 1.20.30
JAVA_VERSION ?= 1.20
edition ?= bedrock
hostuid := $(shell id -u)

export BEDROCK_VERSION
export JAVA_VERSION
export edition
export hostuid

docker:
	docker compose up -d --build

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
	BEDROCK_VERSION=$(BEDROCK_VERSION) \
	JAVA_VERSION=$(JAVA_VERSION) \
	vagrant destroy -f || true
