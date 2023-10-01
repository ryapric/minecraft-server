#!/usr/bin/env bash
set -euo pipefail

edition="${1:-}"
if [[ -z "${edition}" ]] ; then
  printf 'ERROR: Minecraft edition (bedrock|java) not provided as script arg.\n'
  exit 1
fi
if [[ ! "${edition}" =~ bedrock|java ]]; then
  printf 'ERROR: Invalid Minecraft edition, must be one of "bedrock" or "java"\n' > /dev/stderr
  exit 1
fi

# TODO: this will only find the latest -- there should only ever be one, but.
mc_root="$(find /home/minecraft -maxdepth 1 -type d -name 'minecraft-*' | tail -n1)"
cd "${mc_root}/${edition}" || exit 1

exec_start_file="${HOME}/start.sh"

if [[ "${edition}" == 'bedrock' ]] ; then
  exec_start="LD_LIBRARY_PATH=. ./bedrock_server"
  echo "${exec_start}" > "${exec_start_file}"
elif [[ "${edition}" == 'java' ]] ; then
  memory=$(awk '/MemTotal/ { printf("%.0f", $2 * 0.75 / 1000) }' /proc/meminfo) # listed as kB in that file
  exec_start="java -Xms${memory}M -Xmx${memory}M -jar ./java-server.jar --nogui"
  echo "${exec_start}" > "${exec_start_file}"
else
  printf 'ERROR: Invalid Minecraft edition provided -- must be one of (bedrock|java), but you provided "%s".\n' "${edition}"
  exit 1
fi

bash "${exec_start_file}"
