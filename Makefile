SHELL := /usr/bin/env bash


# accountNumber := $$(aws sts get-caller-identity --query Account --output text)
# bucket := minecraft-bedrock-server-$(accountNumber)
ifndef $$CONFIG
	CONFIG := ./config.yaml
endif

server_name := $(shell grep 'server_name' $(CONFIG) | cut -d':' -f2 | tr -d ' ')


help:
	@printf "See Makefile for available targets\n"

deploy: cfn-deploy ansible-configure-bedrock-server

# This renders all Jinja templates in the repo with your secure, gitignored values
render-all:
	@printf "Rendering all Jinja templates...\n"
	@find . -regex '.*_jinja.*' -print0 | xargs -0 -I{} python3 render-all.py {}

##################
# CloudFormation #
##################
cfn-deploy: render-all
	aws cloudformation deploy \
		--no-fail-on-empty-changeset \
		--stack-name BedrockServer-$(server_name) \
		--template-file aws-cloudformation/BedrockServer.yaml \
		--tags 'Owner=ryapric@gmail.com' \
		--capabilities CAPABILITY_IAM

cfn-delete:
	@aws cloudformation delete-stack --stack-name bedrockServer
	@printf "Stack delete request sent. Waiting for delete completion...\n"
	@aws cloudformation wait stack-delete-complete --stack-name bedrockServer
	@printf "Done.\n"

cfn-test: render-all
	@pytest -v -s tests/test-stack.py


###########
# Ansible #
###########
get-latest-bedrock-version:
	@printf "Looking up latest Bedrock Server version...\n"
	@curl -fsSL https://www.minecraft.net/en-us/download/server/bedrock/ \
	| grep 'https://minecraft.azureedge.net/bin-linux/bedrock-server-' \
	| sed -E 's/.*a href=".*bin-linux\/bedrock-server-(.*)\.zip".*/\1/' > /tmp/bedrock-version
	@printf "Latest version: $(shell cat /tmp/bedrock-version), adding to config.yaml\n"
	@sed -E -i 's/bedrock_server_version: .*/bedrock_server_version: "'$(shell cat /tmp/bedrock-version)'"/g' config.yaml

ansible-configure-bedrock-server: render-all get-latest-bedrock-version
	cd ansible && ansible-playbook ./bedrock-server/main.yaml

ansible-configure-phantom-proxy: render-all
	cd ansible && ansible-playbook ./phantom-proxy/main.yaml
