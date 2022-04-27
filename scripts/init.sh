#!/usr/bin/env bash
set -euo pipefail

###

printf 'Moving this script to a permanent location if you need it later...\n'

cp "${BASH_SOURCE[0]}" /usr/bin/minecraft-init
chmod +x /usr/bin/minecraft-init

###

printf 'Setting up some system utilities...\n'

apt-get update && apt-get install -y \
  htop \
  unzip \
  zip

###

# TODO: printf 'Setting up data backup & retrieval services...\n'

###

printf 'Downloading Minecraft Bedrock server...\n'
{
  curl -fsSL 'https://minecraft.fandom.com/wiki/Bedrock_Dedicated_Server' > /tmp/wiki.html
} || exit 1
download_url=$(grep -Eo "https://minecraft.azureedge.net/bin-linux/bedrock-server-.*.zip" /tmp/wiki.html | tail -n1)
version=$(sed -E 's;^.*-([0-9]\..*)\.zip$;\1;' <<< "${download_url}")
export version
curl -fsSL -o /tmp/minecraft-"${version}".zip "${download_url}" || exit 1

export workdir=/home/admin/minecraft-"${version}"
mkdir -p "${workdir}"
unzip -d "${workdir}"/ /tmp/minecraft-"${version}".zip || exit 1
chown -R admin:admin "${workdir}"

###

# TODO: printf 'Replacing settings files with your own...\n'

###

printf 'Setting up systemd service for Minecraft...\n'

cat <<EOF >/etc/systemd/system/minecraft-bedrock-server.service
[Unit]
Description=Minecraft Bedrock Server

[Service]
ExecStart=${workdir}/bedrock_server
User=admin
Environment=LD_LIBRARY_PATH=${workdir}
WorkingDirectory=${workdir}
StandardOutput=file:${workdir}/bedrock-server.log
StandardError=file:${workdir}/bedrock-server.log
Restart=always
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl start minecraft-bedrock-server.service
systemctl enable minecraft-bedrock-server.service

sleep 3
systemctl is-active minecraft-bedrock-server.service || {
  journalctl -n10 -u minecraft-bedrock-server.service
  exit 1
}

printf 'Done.\n'

###
