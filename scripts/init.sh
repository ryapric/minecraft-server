#!/usr/bin/env bash
set -euo pipefail

###

export edition="${1:-}"
export version="${2:-}"
export platform="${3:-}"

if [[ -z "${edition}" ]]; then
  printf 'ERROR: Minecraft edition (bedrock|java) not set as first arg to init script, aborting\n' > /dev/stderr
  exit 1
elif [[ ! "${edition}" =~ bedrock|java ]]; then
  printf 'ERROR: Invalid Minecraft edition, must be one of "bedrock" or "java", aborting\n' > /dev/stderr
  exit 1
fi
if [[ -z "${version}" ]]; then
  printf 'ERROR: version string not set as second arg to init script, aborting\n' > /dev/stderr
  exit 1
fi
if [[ -z "${platform}" ]]; then
  printf 'WARNING: platform not set as third arg to init script, so some features (like backups) will not be enabled\n' > /dev/stderr
else
  printf "Platform '%s' provided to init script; will try to set up associated features if applicable\n" "${platform}"
fi

# Tried to get this to work in a case-block, but expression needs to be evaluated first, so
if id -u admin > /dev/null 2>&1 ; then
  export mcuser=admin
elif id -u vagrant > /dev/null 2>&1 ; then
  export mcuser=vagrant
else
  export mcuser="${USER}"
fi

###

until [[ -d /tmp/server-cfg/"${edition}" ]]; do
  printf 'Waiting for Minecraft %s config files to land on the host...\n' "${edition^}"
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
  openjdk-17-jre-headless \
  unzip \
  zip

###

printf 'Minecraft %s version provided as %s; will try to use that.\n' "${edition^}" "${version}"
# tail -n1 still here in case your provided version is too short and returns
# multiple results
# TODO: The MC wiki does a good job snapshotting specific server versions, so we're using those right now
# Also, the sed call splits tags onto their own newlines so later regexes don't fight back so hard
curl -fsSL "https://minecraft.fandom.com/wiki/${edition^}_Edition_${version}" | sed 's/>/>\n/g' > /tmp/mc-wiki-page.html
if [[ "${edition}" == 'java' ]]; then
  download_url=$(grep -E -o 'https://.*server\.jar' /tmp/mc-wiki-page.html)
else
  download_url=$(grep -E -o 'https://.*bin-linux/.*\.zip' /tmp/mc-wiki-page.html)
fi

printf 'Will use server version %s, and download from %s\n' "${version}" "${download_url}"

version_short=$(sed -E 's/^([0-9]+\.[0-9]+)\..*$/\1/' <<< "${version}")
export version_short
workdir=$(sudo -u "${mcuser}" sh -c 'echo ${HOME}')/minecraft-"${version_short}"/"${edition}"
printf 'Setting server working directory as %s\n' "${workdir}"
export workdir
mkdir -p "${workdir}"

if [[ "${edition}" == 'java' ]]; then
  if [[ -f "${workdir}"/java-server-"${version}".jar ]]; then
    printf "Discovered version's server file is already on this machine, so skipping download\n"
  else
    printf 'Downloading Minecraft %s server v%s...\n' "${edition^}" "${version}"
    curl -fsSL -o "${workdir}"/java-server-"${version}".jar "${download_url}" || exit 1
  fi
else
  if [[ -f /tmp/minecraft-"${version}".zip ]]; then
    printf "Discovered version's server file is already on this machine, so skipping download/unzip\n"
  else
    printf 'Downloading Minecraft %s server v%s...\n' "${edition^}" "${version}"
    curl -fsSL -o /tmp/minecraft-"${version}".zip "${download_url}" || exit 1
    unzip -o -q -d "${workdir}"/ /tmp/minecraft-"${version}".zip || exit 1
  fi
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
cp -r /tmp/server-cfg/"${edition}"/* "${workdir}"/

###

printf 'Setting permissions on server directory...\n'
chown -R "${mcuser}:${mcuser}" /home/"${mcuser}" # "${workdir}"

###

printf 'Setting up systemd service for Minecraft %s...\n' "${edition^}"

if [[ "${edition}" == 'java' ]]; then
  memory=$(awk '/MemTotal/ { printf("%.0f", $2 * 0.75 / 1000) }' /proc/meminfo) # listed as kB in that file
  exec_start="java -Xms${memory}M -Xmx${memory}M -jar ${workdir}/java-server-${version}.jar --nogui"
else
  exec_start="${workdir}/bedrock_server"
fi

cat <<EOF >/etc/systemd/system/minecraft-"${edition}"-server.service
[Unit]
Description=Minecraft ${edition^} Server

[Service]
ExecStart=${exec_start}
User=${mcuser}
Environment=LD_LIBRARY_PATH=${workdir}
WorkingDirectory=${workdir}
StandardOutput=file:${workdir}/${edition}-server.log
StandardError=file:${workdir}/${edition}-server.log
Restart=always
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl start minecraft-"${edition}"-server.service
systemctl enable minecraft-"${edition}"-server.service

printf 'Waiting for server to start up...\n'
sleep 10
systemctl is-active minecraft-"${edition}"-server.service || {
  printf 'ERROR: Minecraft %s server service did not start successfully!\n' "${edition^}"
  journalctl --no-pager -n10 -u minecraft-"${edition}"-server.service
  exit 1
}

###

printf 'All done! Your Minecraft World "%s" should be running!\n' "$(grep 'level-name' "${workdir}"/server.properties | awk -F= '{ print $2 }')"
