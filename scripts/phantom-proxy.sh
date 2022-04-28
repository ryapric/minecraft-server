#!/usr/bin/env bash
set -euo pipefail

if [[ $(basename "$(dirname "${PWD}")") != 'terraform' ]]; then
  printf 'You need to call this script from within your Terraform deployment directory, so it can find the Minecraft server address!\n' 2>&1
  exit 1
fi

printf 'Finding latest Phantom proxy version...\n'
version=$(git ls-remote --tags https://github.com/jhead/phantom.git | tail -n1 | sed -E 's;^.*refs/tags/v(.*)$;\1;')

bindir="${HOME}"/.local/bin
mkdir -p "${bindir}"

if [[ ! -f "${bindir}"/phantom-proxy-"${version}" ]]; then
  printf 'Latest Phantom proxy version not found in %s; downloading...\n' "${bindir}"
  curl \
    -fsSL \
    -o "${bindir}"/phantom-proxy-"${version}" \
    "https://github.com/jhead/phantom/releases/download/v${version}/phantom-linux"
  chmod +x "${bindir}"/phantom-proxy-"${version}"
fi

if [[ "${1:-}" == 'start' ]]; then
  printf 'Starting Phantom proxy as requested...\n'
  "${bindir}"/phantom-proxy-"${version}" -server "$(terraform output -raw server_ip):19132"
fi
