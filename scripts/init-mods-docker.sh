#!/usr/bin/env bash
set -euo pipefail

################################################################################
# NOTE: I took the steps from the following guide, and tried to automate them:
# https://nodecraft.com/support/games/minecraft-bedrock/how-to-install-addons-to-your-minecraft-bedrock-edition-server#h-activating-the-addons-c9aba32
################################################################################

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

# We can't fully process mods until world data & directories exist, so this is a
# context-free check for that condition
if [[ ! -d "${mc_root}"/worlds ]] || [[ "$(find "${mc_root}"/worlds -type d -name 'db' | wc -l)" -eq 0 ]]; then
  printf '>>> WARNING: Cannot process mods until world data exists. Start world for the first time, then fully restart to process mods\n' >&2
  exit 0
fi

# Iterate through Bedrock mods, setting them up and extracting metadata for enablement
for mod_file in /tmp/mods/*.mc* ; do
  printf '>>> Setting up mod from file %s...\n' "${mod_file}"
  mod_name="$(basename "${mod_file%.*}")"
  root_mod_dir="/tmp/mods/${mod_name}"
  unzip -q -u -d "${root_mod_dir}/" "${mod_file}"
  # Some mods are zipped with another directory above the content, so find it here
  real_root_mod_dir="$(dirname "$(find "${root_mod_dir}" -type f -name 'manifest.json')")"
  mkdir -p "${mc_root}/resource_packs/${mod_name}/"
  cp -r "${real_root_mod_dir}"/* "${mc_root}/resource_packs/${mod_name}/"
  jq '{"pack_id": .header.uuid, "version": .header.version}' "${real_root_mod_dir}"/manifest.json > "${root_mod_dir}/${mod_name}_mergeable_metadata.json"
done

# Merge all collected metadata for Bedrock mods
find /tmp/mods -type f -name "*_mergeable_metadata.json" -exec jq -s '[.][0]' {} + > /tmp/world_resource_packs.json
for world in "${mc_root}"/worlds/* ; do
  if [[ "${world}" =~ '/backups' ]] ; then continue ; fi
  printf '>>> Adding metadata JSON files for world directory '%s'...\n' "${world}"
  cp /tmp/world_resource_packs.json "${world}"/
done
