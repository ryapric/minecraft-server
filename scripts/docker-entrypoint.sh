#!/usr/bin/env bash
set -euo pipefail

edition="${1:-}"
if [[ -z "${edition}" ]] ; then
  printf '>>> ERROR: Minecraft edition (bedrock|java) not provided as script arg.\n'
  exit 1
fi
if [[ ! "${edition}" =~ bedrock|java ]]; then
  printf '>>> ERROR: Invalid Minecraft edition, must be one of "bedrock" or "java"\n' > /dev/stderr
  exit 1
fi

mc_root="${HOME}/minecraft-docker/${edition}"
cd "${mc_root}" || exit 1

exec_start_file="${HOME}/start.sh"

if [[ "${edition}" == 'bedrock' ]] ; then
  exec_start="LD_LIBRARY_PATH=${mc_root} ${mc_root}/bedrock_server"
  echo "${exec_start}" > "${exec_start_file}"
elif [[ "${edition}" == 'java' ]] ; then
  # TODO: make overridable later, but use half of host memory
  memory=$(awk '/MemTotal/ { printf("%.0f", $2 * 0.5 / 1000) }' /proc/meminfo) # listed as kB in that file
  exec_start="java -Xms${memory}M -Xmx${memory}M -jar ${mc_root}/java-server.jar --nogui"
  echo "${exec_start}" > "${exec_start_file}"
else
  printf '>>> ERROR: Invalid Minecraft edition provided -- must be one of (bedrock|java), but you provided "%s".\n' "${edition}"
  exit 1
fi

# TODO: this is reall rudimentary, but it works, so.
backup_dir="${mc_root}/worlds/backups"
mkdir -p "${backup_dir}"
make-backups() {
  while true ; do
    backup_file="${backup_dir}/backup-$(date '+%Y-%m-%dT%H-%M-%S').tar.gz"
    printf '>>> Running backup job for file %s...\n' "${backup_file}"
    tar \
      -czf "${backup_file}" \
      --exclude="worlds/backups" \
      ./worlds
    sleep 1800
  done
}
make-backups &

bash "${exec_start_file}"
