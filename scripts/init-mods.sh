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
  cd "${mod_dir}" || exit 1
  mod_name="$(basename ${mod_dir})"
  unzip ./*.mcpack
  mkdir -p "${mc_root}/resource_packs/${mod_name}/"
  [[ -d ./textures ]] && cp -r ./textures/* "${mc_root}/resource_packs/${mod_name}/"
  jq '{"pack_id": .header.uuid, "version": .header.version}' ./manifest.json > "${mod_dir}/${mod_name}_mergeable_metadata.json"
done

# Merge all collected metadata for Bedrock mods
find . -type f -name "*_metadata.json" -exec jq -s '[.][0]' {} + > "${mc_root}/world_resource_packs.json"
