#!/bin/bash

# Elevate script to root if not root already
[[ $UID != 0 ]] && exec sudo -E bash "$(readlink -f $0)" "$@"

set -Eeuo pipefail
shopt -s inherit_errexit

cd "/home/pi/"

# Download and extract binaries
if ! wget "https://github.com/nexmonster/nexmon_csi_bin/raw/main/base/$(uname -r).tar.xz"; then
    echo "Pre-compiled binaries probably don't exist for your kernel's version: $(uname -r)."
    echo "Please create a new Issue on Github and tell us what kernel you are using."
    exit
fi

tar -xvJf "$(uname -r).tar.xz"

# install nexutil
ln -s "/home/pi/$(uname -r)/nexutil/nexutil" "/usr/local/bin/nexutil"

# install makecsiparams
ln -s "/home/pi/$(uname -r)/makecsiparams/makecsiparams" "/usr/local/bin/mcp"
ln -s "/home/pi/$(uname -r)/makecsiparams/makecsiparams" "/usr/local/bin/makecsiparams"

# install firmware and driver
cp "/home/pi/$(uname -r)/patched/brcmfmac43455-sdio.bin" "/lib/firmware/brcm/brcmfmac43455-sdio.bin"
cp "/home/pi/$(uname -r)/patched/brcmfmac.ko" "$(modinfo brcmfmac -n)"

depmod -a