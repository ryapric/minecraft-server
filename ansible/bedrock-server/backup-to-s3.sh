#!/usr/bin/env bash
set -ex

cd /root || exit 1

date

accountNumber=$(aws sts get-caller-identity --query Account --output text)
bucket="minecraft-bedrock-server-${accountNumber}"
server_name=$(grep 'server-name' server.properties | cut -d'=' -f2)
bakfile="backup-${server_name}.tar.gz"

tar -czf "${bakfile}" worlds
aws s3 cp "${bakfile}" "s3://${bucket}/${bakfile}"
