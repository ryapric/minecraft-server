#!/usr/bin/env bash
set -euo pipefail

if [[ -u "${workdir:-}" ]]; then
  printf 'ERROR: workdir var was not passed in by the systemd unit! Exiting.\n' 2>&1
  exit 1
fi

cd "${workdir}" || exit 1

world_name=$(grep 'level-name' "${workdir}"/server.properties | sed -E 's/\s+/_/g' | cut -d'=' -f2) # the sed replaces any whitespace in the server name
world_name="${world_name,,}"
account_number=$(aws sts get-caller-identity --query Account --output text)
bucket="minecraft-bedrock-server-backups-${account_number}"
bakfile="${world_name}.tar.gz"
key="${world_name}/${bakfile}"

if [[ "$1" == 'backup' ]]; then

  tar -C "${workdir}" -czf "${workdir}/${bakfile}" worlds/ server.properties allowlist.json permissions.json
  aws s3 cp "${workdir}/${bakfile}" "s3://${bucket}/${key}"

elif [[ "$1" == 'restore' ]]; then

  if [[ -f "${workdir}/${bakfile}" ]]; then
    printf 'Found existing World data on host; skipping download\n'
    exit 0
  fi

  if aws s3 cp "s3://${bucket}/${key}" "${workdir}/${bakfile}"; then
    printf 'Using discovered World data; size %s\n' "$(du -hs "${workdir}/${bakfile}" | cut -f1)"
    rm -rf "${workdir}"/worlds
    tar -C "${workdir}" -xzf "${workdir}/${bakfile}"
  else
    printf 'No remote backup data exists or is inaccessible; starting with new World\n'
  fi

fi
