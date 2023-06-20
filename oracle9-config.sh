#!/bin/bash

set -e

if [ "$EUID" -eq 0 ]
  then echo "Please do not run as root"
  exit
fi

__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd $__dir

echo "Adding flatpak repositories..."
sleep 1
echo ""
sudo flatpak remote-add -v --if-not-exists --system fedora oci+https://registry.fedoraproject.org
sudo flatpak remote-add -v --if-not-exists --system flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak remote-add -v --if-not-exists fedora oci+https://registry.fedoraproject.org
flatpak remote-add -v --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
echo "" ;echo "Adding system tweaks basic themes and software..."
sleep 1
echo ""
echo "fastestmirror=true" | sudo tee -a /etc/dnf/dnf.conf >/dev/null
echo "max_parallel_downloads=6" | sudo tee -a /etc/dnf/dnf.conf >/dev/null
sudo dnf clean all >/dev/null
cat <<-EOF | sudo tee /etc/sysctl.d/99-systemtweaks.conf >/dev/null
	vm.swappiness=10
	vm.dirty_background_bytes=16777216
	vm.dirty_bytes=33554432
	vm.max_map_count=2147483642
EOF
sudo dnf install -y --nogpgcheck yum-utils https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm https://mirrors.rpmfusion.org/free/el/rpmfusion-free-release-$(rpm -E %rhel).noarch.rpm https://mirrors.rpmfusion.org/nonfree/el/rpmfusion-nonfree-release-$(rpm -E %rhel).noarch.rpm
sudo yum-config-manager --enable crb
sudo dnf makecache
sudo wget -qO /etc/zshrc https://git.grml.org/f/grml-etc-core/etc/zsh/zshrc
sudo dnf install -y sqlite watchdog ./icons/*.rpm ./pop-shell/*.rpm ./steam-prep/*.rpm ./office/*.rpm gnome-extensions-app gnome-tweaks dconf-editor hyphen-en neofetch file-roller zram-generator gnome-extensions-app gnome-tweaks kernel-modules-extra-`uname -r` pavucontrol ufw ffmpeg unrar p7zip p7zip-plugins
sudo usermod $USER -s /bin/zsh
sudo chsh -s /bin/zsh
sudo systemctl disable firewalld >/dev/null 2>&1
sudo systemctl enable ufw >/dev/null 2>&1
sudo systemctl enable watchdog >/dev/null 2>&1
sudo cp ./neofetch/neofetch /usr/bin/neofetch
sudo cp -r ./zram/usr/lib/systemd/* /usr/lib/systemd/
[ -d "$HOME/Desktop" ] || mkdir "$HOME/Desktop"
cp "nvidia/How to install the Nvidia Drivers.pdf" "$HOME/Desktop/How to install the Nvidia Drivers.pdf"
# Change the locale setting to that which is applicable to you.
echo ""; echo "Changing the locale settings to NL while keeping the English language..."
sleep 1
cat <<-EOF | sudo tee /etc/locale.conf >/dev/null
	LANG="en_US.UTF-8"
	LANGUAGE=
	LC_TIME="en_GB.UTF-8"
	LC_CTYPE="en_US.utf-8"
	LC_NUMERIC="nl_NL.utf-8"
	LC_COLLATE="en_US.utf-8"
	LC_MONETARY="nl_NL.utf-8"
	LC_MESSAGES="en_US.utf-8"
	LC_PAPER="nl_NL.utf-8"
	LC_NAME="nl_NL.utf-8"
	LC_ADDRESS="nl_NL.utf-8"
	LC_TELEPHONE="nl_NL.utf-8"
	LC_MEASUREMENT="nl_NL.utf-8"
	LC_IDENTIFICATION="nl_NL.utf-8"
	LC_ALL=
EOF
cat <<-EOF | sudo tee /usr/bin/systemupdate >/dev/null
	#!/bin/bash
	ping -q -w 1 -c 1 \`ip r | grep default | cut -d ' ' -f 3\` >/dev/null && pkcon refresh force && pkcon update --only-download
EOF
cat <<-EOF | sudo tee /etc/xdg/autostart/systemupdate.desktop >/dev/null
[Desktop Entry]
Type=Application
Exec=gnome-terminal -- /usr/bin/systemupdate --title "Checking for updates"
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Icon=system-software-update
Name[en_US]=Update Check
Name=Update Check
Comment[en_US]=
Comment=
EOF
sudo chmod 755 /usr/bin/systemupdate

echo ""; echo "Installing flatpaks..."
sleep 1
echo ""
#sudo -v ; sudo flatpak install -y --noninteractive --system com.valvesoftware.Steam com.github.Matoking.protontricks net.davidotek.pupgui2 com.valvesoftware.Steam.CompatibilityTool.Proton com.valvesoftware.Steam.Utility.steamtinkerlaunch
sudo -v
sudo flatpak install -y --noninteractive --system flathub org.gimp.GIMP/x86_64/stable org.videolan.VLC/x86_64/stable io.mpv.Mpv/x86_64/stable onlyoffice org.gtk.Gtk3theme.Adwaita-dark com.google.Chrome

echo ""; echo "Preparing for updates...  it will automatically reboot."
sleep 3
sudo dnf upgrade -y
sudo systemctl reboot
