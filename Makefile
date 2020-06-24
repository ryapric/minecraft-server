SHELL := /usr/bin/env bash


# accountNumber := $$(aws sts get-caller-identity --query Account --output text)
# bucket := minecraft-bedrock-server-$(accountNumber)


help:
	@printf "See Makefile for available targets\n"

# This renders all Jinja templates in the repo with your secure, gitignored values
render-all:
	@printf "Rendering all Jinja templates...\n"
	@find . -regex '.*_jinja.*' -print0 | xargs -0 -I{} python3 render-all.py {}

##################
# CloudFormation #
##################
cfn-deploy: render-all
	aws cloudformation deploy \
		--stack-name bedrockServer \
		--template-file cloudformation/bedrockServer.yaml \
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
ansible-configure-bedrock-server: render-all
	@cd ansible && ansible-playbook ./bedrock-server/main.yaml

ansible-configure-phantom-proxy: render-all
	@cd ansible && ansible-playbook ./phantom-proxy/main.yaml
