#!/usr/bin/env bash

set -euo pipefail

box_file=${BOX_FILE:?this environment variable is not defined}
box_name=${BOX_NAME:?this environment variable is not defined}
box_version=${BOX_VERSION:?this environment variable is not defined}

if [ ! -r ${box_file} ]; then
  echo Box file ${box_file} not exists or is not readable!
  exit 1
fi

box_hash=$(sha256sum ${box_file} | cut -d " " -f1)

metadata="{
  \"name\": \"${box_name}\",
  \"versions\": [
    {
      \"version\": \"${box_version}\",
      \"providers\": [
        {
          \"name\": \"libvirt\",
          \"url\": \"file://$(realpath ${box_file})\",
          \"checksum\": \"${box_hash}\",
          \"checksum_type\": \"sha256\"
        }
      ]
    }
  ]
}
"

echo "$metadata" > $(dirname ${box_file})/${box_name}.json
