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

if [[ -z "${world_data_dir:-'data/default'}" ]] ; then
  # shellcheck disable=SC2016
  printf 'NOTE: ${world_data_dir} is unset, so will use default of ./data/default\n'
fi
runtime_root="${HOME}/${world_data_dir}"
mkdir -p "${runtime_root}"

mc_root="$(find "${HOME}" -maxdepth 1 -type d -name 'minecraft-*' | tail -n1)"

exec_start_file="${HOME}/start.sh"

if [[ "${edition}" == 'bedrock' ]] ; then
  # Need to copy data from the installed directory to the one we mount -- we
  # can't just mount directly or else it wipes the dir
  cp -r "${mc_root}"/bedrock/* "${runtime_root}"
  exec_start="LD_LIBRARY_PATH=${mc_root} ${mc_root}/bedrock/bedrock_server"
  echo "${exec_start}" > "${exec_start_file}"
elif [[ "${edition}" == 'java' ]] ; then
  # TODO: make overridable later, but use half of host memory
  memory=$(awk '/MemTotal/ { printf("%.0f", $2 * 0.5 / 1000) }' /proc/meminfo) # listed as kB in that file
  # Auto-accept EULA
  echo 'eula=true' > "${runtime_root}"/eula.txt
  exec_start="java -Xms${memory}M -Xmx${memory}M -jar ${mc_root}/java/java-server.jar --nogui"
  echo "${exec_start}" > "${exec_start_file}"
else
  printf 'ERROR: Invalid Minecraft edition provided -- must be one of (bedrock|java), but you provided "%s".\n' "${edition}"
  exit 1
fi

cd "${runtime_root}" || exit 1
bash "${exec_start_file}"
