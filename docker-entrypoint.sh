#!/usr/bin/env bash
set -euo pipefail

edition="${1:-}"
if [[ -z "${edition}" ]] ; then
  printf 'ERROR: Minecraft edition (bedrock|java) not provided as script arg.\n'
  exit 1
fi

workdir="$(cat "${HOME}"/workdir-name)"

if [[ "${edition}" == 'bedrock' ]] ; then
  exec_start="${workdir}/bedrock_server"
elif [[ "${edition}" == 'java' ]] ; then
  memory=$(awk '/MemTotal/ { printf("%.0f", $2 * 0.75 / 1000) }' /proc/meminfo) # listed as kB in that file
  exec_start="java -Xms${memory}M -Xmx${memory}M -jar ${workdir}/java-server-*.jar --nogui"
else
  printf 'ERROR: Invalid Minecraft edition provided -- must be one of (bedrock|java), but you provided "%s".\n' "${edition}"
  exit 1
fi

cd "${workdir}" || exit 1
exec "${exec_start}"
