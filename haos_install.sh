#!/bin/bash
set -e
set -x
if [ -e /root/.haos_ok ]; then
  exit 0
fi

echo waiting for internet connection...
while ! ping -c 1 -W 1 8.8.8.8 > /dev/null 2>&1; do
  sleep 1
done
echo nameserver 8.8.8.8 > /etc/resolv.conf
echo homeassistant > /etc/hostname
sed -i 's#PRETTY_NAME=.*#PRETTY_NAME="Debian GNU/Linux 12 (bookworm)"#' /etc/os-release
echo extraargs=systemd.unified_cgroup_hierarchy=0 apparmor=1 security=apparmor >> /boot/armbianEnv.txt
apt update
apt install -y apparmor cifs-utils curl dbus jq libglib2.0-bin lsb-release network-manager nfs-common systemd-journal-remote systemd-resolved udisks2 wget bluez
systemctl restart systemd-resolved.service
systemctl restart NetworkManager
curl -fsSL get.docker.com | sh
cd /tmp
wget -O os-agent.deb https://github.com/home-assistant/os-agent/releases/download/1.7.2/os-agent_1.7.2_linux_aarch64.deb
dpkg -i os-agent.deb
sudo apt remove -y apparmor
sudo wget http://ftp.debian.org/debian/pool/main/a/apparmor/apparmor_2.13.6-10_arm64.deb
sudo apt install ./apparmor_2.13.6-10_arm64.deb
wget -O homeassistant-supervised.deb https://github.com/home-assistant/supervised-installer/releases/download/3.0.0/homeassistant-supervised.deb
echo "homeassistant-supervised ha/machine-type select qemuarm-64" | debconf-set-selections
DEBIAN_FRONTEND=noninteractive dpkg -i homeassistant-supervised.deb
sed -i 's#renderer: .*#renderer: NetworkManager#' /etc/netplan/*.yaml
curl -sL https://version.home-assistant.io/apparmor_stable.txt > /var/lib/homeassistant/apparmor/hassio-supervisor
touch /root/.haos_ok
reboot