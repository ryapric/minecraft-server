SHELL := /usr/bin/env bash -euo pipefail

# These need to be separate because the lookup behavior for each of them is
# different -- Bedrock needs Major-Minor-Patch, Java just needs Major-Minor
#
# You can look up available versions at:
# Bedrock: https://minecraft.wiki/w/Bedrock_Dedicated_Server#Release_versions
# Java: https://minecraft.wiki/w/Java_Edition_{version} (there's no index page at the time of this writing)
bedrock_version ?= 1.21.1
java_version ?= 1.21

edition ?= bedrock
level_name ?= not-provided-by-user
hostuid := $(shell id -u)

export bedrock_version
export java_version
export edition
export level_name
export hostuid

docker:
	@mkdir -p data/
	@export bedrock_version=$(bedrock_version); \
	export java_version=$(java_version); \
	export edition=$(edition); \
	export level_name=$(level_name); \
	export hostuid=$(hostuid); \
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

# As indicated by the name, this does NOT copy world data -- that's risky
# business that I don't want to deal with accidentally overwriting
copy-code-to-remote:
	@if [[ -z "$${remote:-}" ]] ; then printf '>>> Must set $$remote env var\n' && exit 1 ; fi
	@rsync -azv --update --exclude=data/ --exclude=.vagrant/ ./ $(remote):minecraft-server --dry-run ; \
	read -p 'WARNING: the above files will be copied TO the remote. Are you sure you want to do this? ' confirmation ; \
	if [[ "$${confirmation}" =~ y|Y ]] ; then \
		rsync -azv --update --exclude=data/ ./ $(remote):minecraft-server ; \
	fi

start-on-remote:
	@if [[ -z "$${remote:-}" ]] ; then printf '>>> Must set $$remote env var\n' && exit 1 ; fi
	@ssh $(remote) -- make -C minecraft-server docker

stop:
	docker compose down || true
	bedrock_version=$(bedrock_version) \
	java_version=$(java_version) \
	vagrant destroy -f || true
