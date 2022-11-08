#!/bin/bash
set -Eeuo pipefail
shopt -s inherit_errexit

cd "/home/pi/.picsi/bins/$(uname -r)/"

# remove nexutil
rm "/usr/local/bin/nexutil"

# remove makecsiparams
rm "/usr/local/bin/mcp"
rm "/usr/local/bin/makecsiparams"

# restore original firmware and driver
cp "$PWD/original/brcmfmac43455-sdio.bin" "/lib/firmware/brcm/brcmfmac43455-sdio.bin"
cp "$PWD/original/brcmfmac.ko" "$(modinfo brcmfmac -n)"

depmod -a

# install wpa_supplicant
sed -zi 's/denyinterfaces wlan0\ninterface wlan0\n\tnohook wpa_supplicant\n//g' /etc/dhcpcd.conf

apt update
apt install -y wpasupplicant
systemctl enable --now wpa_supplicant

rm -rf "/home/pi/.picsi/"

echo "Done. Please reboot."
