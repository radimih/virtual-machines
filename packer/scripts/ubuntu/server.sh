#!/bin/sh -eux

# Based on: https://github.com/chef/bento/blob/main/packer_templates/ubuntu/scripts/cleanup.sh

echo "remove all linux-headers"
dpkg --list \
    | awk '{ print $2 }' \
    | grep 'linux-headers' \
    | xargs apt-get -y purge;

echo "remove all development packages"
dpkg --list \
    | awk '{ print $2 }' \
    | grep -- '-dev\(:[a-z0-9]\+\)\?$' \
    | xargs apt-get -y purge;

echo "remove X11 libraries"
apt-get -y purge libx11-data xauth libxmuu1 libxcb1 libx11-6 libxext6;

echo "remove packages we don't need"
apt-get -y purge laptop-detect usbutils
