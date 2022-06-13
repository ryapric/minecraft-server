#!/usr/bin/env bash
set -euo pipefail

###

export platform="${1:-}"

# Tried to get this to work in a case-block, but expression needs to be evaluated first, so
if id -u admin > /dev/null 2>&1 ; then
  export mcuser=admin
elif id -u vagrant > /dev/null 2>&1 ; then
  export mcuser=vagrant
else
  export mcuser="${USER}"
fi

###

if [[ -z "${platform}" ]]; then
  printf 'WARNING: platform not set as arg to init script, so some features (like backups) will not be enabled\n' > /dev/stderr
else
  printf "Platform '%s' provided to init script; will try to set up associated features\n" "${platform}"
fi

###

until [[ -d /tmp/bedrock-server-cfg ]]; do
  printf 'Waiting for Minecraft Bedrock config files to land on the host...\n'
  sleep 5
done

###

printf 'Moving this script to a permanent location (%s) if you need it later...\n' /usr/local/bin/minecraft-init
cp "${BASH_SOURCE[0]}" /usr/local/bin/minecraft-init || true
chmod +x /usr/local/bin/minecraft-init

###

printf 'Setting up some system utilities...\n'
apt-get update
apt-get install -y \
  curl \
  htop \
  unzip \
  zip

###

printf 'Getting available server versions...\n'

{
  curl -fsSL \
    'https://minecraft.fandom.com/wiki/Bedrock_Dedicated_Server' \
    | grep -E 'azure.*linux.*\.zip.*' \
  > /tmp/mc-versioned-urls.html
} || exit 1
sed -i -E 's/.*(https:.*\.zip).*/\1/' /tmp/mc-versioned-urls.html

# Let user provide a version, but default to latest available
if [[ -z "${version:-}" ]]; then
  version=$(
    tail -n1 /tmp/mc-versioned-urls.html \
    | sed -E 's;^.*-([0-9]\..*)\.zip$;\1;'
  )
  printf 'Found latest Minecraft Bedrock version to be %s\n' "${version}"
else
  printf 'Minecraft Bedrock version provided as %s; will try to use that.\n' "${version}"
  # tail -n1 still here in case your provided version is too short and returns
  # multiple results
  version=$(
    grep "${version}" /tmp/mc-versioned-urls.html \
    | tail -n1  \
    | sed -E 's;^.*-([0-9]\..*)\.zip$;\1;'
  )
fi
export version
download_url=$(grep "${version}" /tmp/mc-versioned-urls.html)

printf 'Will use server version %s, and download from %s\n' "${version}" "${download_url}"

version_short=$(sed -E 's/^([0-9]+\.[0-9]+)\..*$/\1/' <<< "${version}")
export version_short
workdir=$(sudo -u "${mcuser}" sh -c 'echo ${HOME}')/minecraft-"${version_short}"
printf 'Setting server working directory as %s\n' "${workdir}"
export workdir

if [[ -f /tmp/minecraft-"${version}".zip ]]; then
  printf "Discovered version's zipfile is already on this machine, so skipping download/unzip\n"
else
  printf 'Downloading Minecraft Bedrock server v%s...\n' "${version}"
  curl -fsSL -o /tmp/minecraft-"${version}".zip "${download_url}" || exit 1
  mkdir -p "${workdir}"
  unzip -o -q -d "${workdir}"/ /tmp/minecraft-"${version}".zip || exit 1
fi

###

# TODO: fork this in a case block to associated scripts
if [[ "${platform}" == 'aws' ]]; then

command -v aws > /dev/null || {
  printf 'Trying to get the latest version of the AWS CLI...\n'
  curl -fsSL 'https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip' -o /tmp/awscliv2.zip
  unzip -o -q -d /tmp /tmp/awscliv2.zip || exit 1
  sudo /tmp/aws/install
}

printf 'Setting up world data backup service...\n'
cp /tmp/scripts/backups-s3.sh /usr/local/bin/minecraft-backups-s3
chmod +x /usr/local/bin/minecraft-backups-s3

# TODO: backup happens on shutdown as expected, but NOT when an EC2 instance is
# terminated during e.g. recreation Need to debug.
cat <<EOF > /etc/systemd/system/minecraft-bedrock-server-backup.service
[Unit]
Description=Minecraft Bedrock Server world data backup service
Wants=minecraft-bedrock-server-backup.timer
After=network.target
Before=poweroff.target shutdown.target reboot.target halt.target

[Service]
ExecStart=/usr/local/bin/minecraft-backups-s3 backup
User=${mcuser}
Type=oneshot
Environment=workdir=${workdir}

[Install]
WantedBy=multi-user.target poweroff.target shutdown.target reboot.target halt.target
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

systemctl enable minecraft-bedrock-server-backup.service # enabled for shutdown-time backup to work
systemctl start minecraft-bedrock-server-backup.timer
systemctl enable minecraft-bedrock-server-backup.timer

###

printf 'Checking if remote world data exists and needs to be restored...\n'
/usr/local/bin/minecraft-backups-s3 restore

# END platform fork
fi

###

printf 'Replacing settings files with your own...\n'
cp /tmp/bedrock-server-cfg/* "${workdir}"/

###

printf 'Setting permissions on server directory...\n'
chown -R "${mcuser}:${mcuser}" "${workdir}"

###

printf 'Setting up systemd service for Minecraft...\n'
cat <<EOF >/etc/systemd/system/minecraft-bedrock-server.service
[Unit]
Description=Minecraft Bedrock Server

[Service]
ExecStart=${workdir}/bedrock_server
User=${mcuser}
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
  journalctl --no-pager -n10 -u minecraft-bedrock-server.service
  exit 1
}

###

printf 'All done! Your Minecraft World "%s" should be running!\n' "$(grep 'level-name' "${workdir}"/server.properties | awk -F= '{ print $2 }')"
