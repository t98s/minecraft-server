#!/bin/bash -eu
set -o pipefail
buf="$(mktemp)"
find ./gcf-minecraft-starter -type f | sort | xargs sha256sum | md5sum | awk '{ print $1 }' > $buf
echo "gcf-minecraft-starter_$(cat $buf).zip"
