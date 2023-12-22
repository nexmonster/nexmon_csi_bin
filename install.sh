#!/bin/bash
set -Eeuo pipefail
shopt -s inherit_errexit

cd "/home/pi/" # best way to ensure this is a Pi lol

mkdir -p "/home/pi/.picsi/bins/" && cd "$_"


KERNEL_VERSION=$(uname -r)

# Latest Raspi OS uses 64-bit kernel, but 32-bit userland
# So we install 32-bit binaries and edit /boot/config.txt
# to use 32-bit kernel. So many hacks.
if [ "$KERNEL_VERSION" = "6.1.21-v8+" ]; then
    KERNEL_VERSION="6.1.21-v7l+"

    echo "NOTE: editing /boot/config.txt to use 32-bit kernel."

    # Force load 32-bit kernel. Requires reboot.
    echo "arm_64bit=0" | sudo tee -a /boot/config.txt > /dev/null
fi

# Download and extract binaries
if ! wget "https://github.com/nexmonster/nexmon_csi_bin/raw/main/base/$KERNEL_VERSION.tar.xz"; then
    echo "Pre-compiled binaries probably don't exist for your kernel's version: $KERNEL_VERSION."
    echo "Please create a new Issue on Github and tell us which kernel you are using."
    exit
fi

tar -xvJf "$KERNEL_VERSION.tar.xz" && cd "$KERNEL_VERSION"

# install nexutil
ln -s "$PWD/nexutil/nexutil" "/usr/local/bin/nexutil"

# install makecsiparams
ln -s "$PWD/makecsiparams/makecsiparams" "/usr/local/bin/mcp"
ln -s "$PWD/makecsiparams/makecsiparams" "/usr/local/bin/makecsiparams"

# install firmware and driver
cp "$PWD/patched/brcmfmac43455-sdio.bin" "/lib/firmware/brcm/brcmfmac43455-sdio.bin"
cp "$PWD/patched/brcmfmac.ko" "$(modinfo brcmfmac -n)"

depmod -a

# Unblock wifi
rfkill unblock all

# Set WiFi country and expand storage
raspi-config nonint do_wifi_country US || true
raspi-config nonint do_expand_rootfs || true

# Install tcpdump
apt update -y
apt install -y tcpdump

# disable wpa_supplicant
printf "denyinterfaces wlan0\\ninterface wlan0\\n\\tnohook wpa_supplicant\\n" >> /etc/dhcpcd.conf
killall "wpa_supplicant"
systemctl disable --now wpa_supplicant
apt remove -y wpasupplicant

echo "Done. Please reboot and see the Usage section for Nexmon_csi."
