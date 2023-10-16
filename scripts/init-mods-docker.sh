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

printf '>>> Processing any discovered mods/addons...\n'

# Iterate through Bedrock mods, setting them up and extracting metadata for enablement
for mod_dir in /tmp/mods/* ; do
  printf '>>> Setting up mod from directory %s...\n' "${mod_dir}"
  cd "${mod_dir}" || exit 1
  mod_name="$(basename "${mod_dir}")"
  unzip ./*.mcpack && rm -f ./*.mcpack
  mkdir -p "${mc_root}/resource_packs/${mod_name}/"
  cp -r ./* "${mc_root}/resource_packs/${mod_name}/"
  jq '{"pack_id": .header.uuid, "version": .header.version}' ./manifest.json > "${mod_dir}/${mod_name}_mergeable_metadata.json"
done

# Merge all collected metadata for Bedrock mods
find . -type f -name "*_mergeable_metadata.json" -exec jq -s '[.][0]' {} + > /tmp/world_resource_packs.json
for world in "${mc_root}"/worlds/* ; do
  printf '>>> Adding metadata JSON files for world directory '%s'...\n' "${world}"
  cp /tmp/world_resource_packs.json "${world}"/
done
