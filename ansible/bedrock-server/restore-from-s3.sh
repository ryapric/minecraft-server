#!/usr/bin/env bash
set -x

cd /root || exit 1

accountNumber=$(aws sts get-caller-identity --query Account --output text)
bucket="minecraft-bedrock-server-${accountNumber}"
bakfile="bedrock-server-backup.tar.gz"
logfile="bedrock-server.log"

if [[ -f "${bakfile}" ]]; then
  printf "Found existing world data on host; skipping download\n" >> "${logfile}"
  exit 0
fi

if aws s3 cp "s3://${bucket}/${bakfile}" "${bakfile}"; then
  printf "Using discovered World data; size $(du -hs ${bakfile} | cut -f1)\n" >> "${logfile}"
  rm -rf /root/worlds
  tar -vxzf "${bakfile}" >> "${logfile}" 2>&1
else
  printf "No remote backup data exists or is inaccessible; starting with new World\n" >> "${logfile}"
fi
