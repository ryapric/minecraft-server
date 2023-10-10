#!/usr/bin/env bash
set -euo pipefail

if [[ -u "${mc_root:-}" ]]; then
  printf '>>> ERROR: mc_root var was not passed in by the systemd unit! Exiting.\n' 2>&1
  exit 1
fi
if [[ -u "${edition:-}" ]]; then
  printf '>>> ERROR: edition var was not passed in by the systemd unit! Exiting.\n' 2>&1
  exit 1
fi


# If there's no server.properties in the mc_root yet (or if it's using the
# default leve/world name), check /tmp/server-cfg. If neither, exit
# gracefully
if [[ -f "${mc_root}/${edition}"/server.properties ]] && ! grep -q 'level-name=Bedrock level' "${mc_root}/${edition}"/server.properties ; then
  server_properties="${mc_root}/${edition}"/server.properties
elif [[ -f /tmp/server-cfg/bedrock/server.properties ]]; then
  server_properties=/tmp/server-cfg/"${edition}"/server.properties
else
  printf '>>> No remote backup data exists or is inaccessible; starting with new World\n'
  exit 0
fi

cd "${mc_root}/${edition}" || exit 1

cmd="${1:-}"

world_name=$(grep 'level-name' "${server_properties}" | sed -E 's/\s+/_/g' | cut -d'=' -f2) # the sed replaces any whitespace in the server name
world_name="${world_name,,}"
account_number=$(aws sts get-caller-identity --query Account --output text)
bucket="minecraft-server-backups-${account_number}"
bakfile="${world_name}.tar.gz"
key="${world_name}/${bakfile}"

if [[ "${cmd}" == 'backup' ]]; then

  tar -C "${mc_root}/${edition}" -czf "${mc_root}/${edition}/${bakfile}" worlds/ server.properties allowlist.json permissions.json
  aws s3 cp "${mc_root}/${edition}/${bakfile}" "s3://${bucket}/${key}"

elif [[ "${cmd}" == 'restore' ]]; then

  if [[ -f "${mc_root}/${edition}/${bakfile}" ]]; then
    printf '>>> Found existing World data on host; skipping download\n'
    exit 0
  fi

  if aws s3 cp "s3://${bucket}/${key}" "${mc_root}/${edition}/${bakfile}"; then
    printf '>>> Using discovered World data; size %s\n' "$(du -hs "${mc_root}/${edition}/${bakfile}" | cut -f1)"
    rm -rf "${mc_root}/${edition}"/worlds
    tar -C "${mc_root}/${edition}" -xzf "${mc_root}/${edition}/${bakfile}"
    # TODO: brittle to always succeed, but eh
    systemctl restart minecraft-"${edition}"-server.service > /dev/null 2>&1 || true
  else
    printf '>>> No remote backup data exists or is inaccessible; starting with new World\n'
  fi

else
  printf "ERROR: Command must be one of 'backup' or 'restore'\n" 2>&1
  exit 1
fi
