#!/usr/bin/env bash
set -euo pipefail

if [[ -u "${workdir:-}" ]]; then
  printf 'ERROR: workdir var was not passed in by the systemd unit! Exiting.\n' 2>&1
  exit 1
fi

# If there's no server.properties in the workdir yet (or if it's using the
# default leve/world name), check /tmp/bedrock-server-cfg. If neither, exit
# gracefully
if [[ -f "${workdir}"/server.properties ]] && ! grep -q 'level-name=Bedrock level' "${workdir}"/server.properties ; then
  server_properties="${workdir}"/server.properties
elif [[ -f /tmp/bedrock-server-cfg/server.properties ]]; then
  server_properties=/tmp/bedrock-server-cfg/server.properties
else
  printf 'No remote backup data exists or is inaccessible; starting with new World\n'
  exit 0
fi

cd "${workdir}" || exit 1

cmd="${1:-}"

world_name=$(grep 'level-name' "${server_properties}" | sed -E 's/\s+/_/g' | cut -d'=' -f2) # the sed replaces any whitespace in the server name
world_name="${world_name,,}"
account_number=$(aws sts get-caller-identity --query Account --output text)
bucket="minecraft-bedrock-server-backups-${account_number}"
bakfile="${world_name}.tar.gz"
key="${world_name}/${bakfile}"

if [[ "${cmd}" == 'backup' ]]; then

  tar -C "${workdir}" -czf "${workdir}/${bakfile}" worlds/ server.properties allowlist.json permissions.json
  aws s3 cp "${workdir}/${bakfile}" "s3://${bucket}/${key}"

elif [[ "${cmd}" == 'restore' ]]; then

  if [[ -f "${workdir}/${bakfile}" ]]; then
    printf 'Found existing World data on host; skipping download\n'
    exit 0
  fi

  if aws s3 cp "s3://${bucket}/${key}" "${workdir}/${bakfile}"; then
    printf 'Using discovered World data; size %s\n' "$(du -hs "${workdir}/${bakfile}" | cut -f1)"
    rm -rf "${workdir}"/worlds
    tar -C "${workdir}" -xzf "${workdir}/${bakfile}"
    # TODO: brittle to always succeed, but eh
    systemctl restart minecraft-bedrock-server.service > /dev/null 2>&1 || true
  else
    printf 'No remote backup data exists or is inaccessible; starting with new World\n'
  fi

else
  printf "ERROR: Command must be one of 'backup' or 'restore'\n" 2>&1
  exit 1
fi
