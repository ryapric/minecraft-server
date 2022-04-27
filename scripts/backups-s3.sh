#!/usr/bin/env bash
set -euo pipefail

if [[ -u "${workdir:-}" ]]; then
  printf 'ERROR: workdir var was not passed in by the systemd unit! Exiting.\n' 2>&1
  exit 1
fi

cd "${workdir}" || exit 1

server_name=$(grep 'server-name' "${workdir}"/server.properties | cut -d'=' -f2)
server_name="${server_name,,}"
account_number=$(aws sts get-caller-identity --query Account --output text)
bucket="minecraft-bedrock-server-backups-${account_number}"
bakfile="${workdir}/${server_name}.tar.gz"
key="${server_name}/${bakfile}"

if [[ "$1" == 'backup' ]]; then

  tar -czf "${workdir}/${bakfile}" worlds
  aws s3 cp "${workdir}/${bakfile}" "s3://${bucket}/${key}"

elif [[ "$1" == 'restore' ]]; then

  if [[ -f "${workdir}/${bakfile}" ]]; then
    printf 'Found existing world data on host; skipping download\n'
    exit 0
  fi

  if aws s3 cp "s3://${bucket}/${key}" "${workdir}/${bakfile}"; then
    printf 'Using discovered World data; size %s\n' "$(du -hs "${workdir}/${bakfile}" | cut -f1)"
    rm -rf "${workdir}"/worlds
    tar -C "${workdir}" -vxzf "${workdir}/${bakfile}"
  else
    printf 'No remote backup data exists or is inaccessible; starting with new World\n'
  fi

fi
