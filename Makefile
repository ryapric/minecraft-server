SHELL := /usr/bin/env bash -euo pipefail

# These need to be separate because the lookup behavior for each of them is
# different -- Bedrock needs Major-Minor-Patch, Java just needs Major-Minor
bedrock_version ?= 1.20.30
java_version ?= 1.20

edition ?= bedrock
hostuid := $(shell id -u)

world_data_dir ?= ./data/default

export bedrock_version
export java_version
export edition
export hostuid
export world_data_dir

docker:
	@mkdir -p $(world_data_dir)
	@export bedrock_version=$(bedrock_version); \
	export java_version=$(java_version); \
	export edition=$(edition); \
	export hostuid=$(hostuid); \
	export world_data_dir=$(world_data_dir); \
	BUILDKIT_PROGRESS=plain \
	docker compose up -d --build

docker-logs:
	docker compose logs

vagrant:
	bedrock_version=$(bedrock_version) \
	java_version=$(java_version) \
	vagrant up $(edition)

aws:
	terraform -chdir=./terraform/aws init -backend-config=backend.tfvars
	terraform -chdir=./terraform/aws apply

local:
	if [[ $(edition) == 'bedrock' ]] ; then \
		version=$(bedrock_version) ; \
	else \
		version=$(java_version) ; \
	fi ; \
	./scripts/init.sh bedrock "$${version}" local

copy-to-remote:
	@if [[ -z "$${remote:-}" ]] ; then printf 'Must set $$remote env var\n' && exit 1 ; fi
	@rsync --update -azv ./ $(remote):minecraft-server

copy-from-remote:
	@if [[ -z "$${remote:-}" ]] ; then printf 'Must set $$remote env var\n' && exit 1 ; fi
	@rsync --update -azv $(remote):minecraft-server/ .

start-on-remote:
	@if [[ -z "$${remote:-}" ]] ; then printf 'Must set $$remote env var\n' && exit 1 ; fi
	@ssh $(remote) -- make -C minecraft-server docker

stop:
	docker compose down || true
	bedrock_version=$(bedrock_version) \
	java_version=$(java_version) \
	vagrant destroy -f || true
