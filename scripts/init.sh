#!/usr/bin/env bash
set -euo pipefail

###

until [[ -d /tmp/bedrock-server-cfg ]]; do
  printf 'Waiting for Minecraft Bedrock config files to land on the host...\n'
  sleep 5
done

###

printf 'Moving this script to a permanent location if you need it later...\n'
cp "${BASH_SOURCE[0]}" /usr/local/bin/minecraft-init || true
chmod +x /usr/local/bin/minecraft-init

###

printf 'Setting up some system utilities...\n'
apt-get update && apt-get install -y \
  htop \
  unzip \
  zip

###

printf 'Downloading Minecraft Bedrock server...\n'
{
  curl -fsSL 'https://minecraft.fandom.com/wiki/Bedrock_Dedicated_Server' > /tmp/wiki.html
} || exit 1
download_url=$(grep -Eo "https://minecraft.azureedge.net/bin-linux/bedrock-server-.*.zip" /tmp/wiki.html | tail -n1)
version=$(sed -E 's;^.*-([0-9]\..*)\.zip$;\1;' <<< "${download_url}")
export version
printf 'Found latest Minecraft Bedrock version to be %s\n' "${version}"
curl -fsSL -o /tmp/minecraft-"${version}".zip "${download_url}" || exit 1

export workdir=/home/admin/minecraft-"${version}"
mkdir -p "${workdir}"
unzip -d "${workdir}"/ /tmp/minecraft-"${version}".zip || exit 1

###

printf 'Setting up world data backup service...\n'
cp /tmp/scripts/backups-s3.sh /usr/local/bin/minecraft-backups-s3
chmod +x /usr/local/bin/minecraft-backups-s3

cat <<EOF > /etc/systemd/system/minecraft-bedrock-server-backup.service
[Unit]
Description=Minecraft Bedrock Server world data backup service
Wants=minecraft-bedrock-server-backup.timer

[Service]
ExecStart=/usr/local/bin/minecraft-backups-s3 backup
User=admin
Type=oneshot
Environment=workdir=${workdir}

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF > /etc/systemd/system/minecraft-bedrock-server-backup.timer
[Unit]
Description=Periodically back up Minecraft Bedrock Server world data
Requires=minecraft-bedrock-server-backup.service

[Timer]
Unit=minecraft-bedrock-server-backup.service
OnCalendar=hourly
Persistent=true

[Install]
WantedBy=timers.target
EOF

# Idempotent creation of worlds folder, so first backup doesn't show a failure in the logs
mkdir -p "${workdir}"/worlds

systemctl start minecraft-bedrock-server-backup.timer
systemctl enable minecraft-bedrock-server-backup.timer

###

printf 'Checking if remote world data exists and needs to be restored...\n'
/usr/local/bin/minecraft-backups-s3 restore

###

printf 'Replacing settings files with your own...\n'
cp /tmp/bedrock-server-cfg/* "${workdir}"/

###

printf 'Setting permissions on server directory...\n'
chown -R admin:admin "${workdir}"

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

###

printf 'All done! Minecraft should be running!\n'
