#!/bin/bash

airootfs=(airootfs/etc)

# Grub

mkdir -p "$airootfs/default"
cp -r "/etc/default/grub" "$airootfs/default"

# os-release
cp -r "/usr/lib/os-release" $airootfs
sed -i 's/NAME="Arch Linux"/NAME="Nimbus OS"/' $airootfs/os-release

# Wheel Group
mkdir -p "$airootfs/sudoers.d"
g_wheel=($airootfs/sudoers.d/q_wheel)
echo "%wheel ALL=(ALL:ALL) ALL" > $q_wheel

# Sym Links
## NetworkManager
mkdir -p "$airootfs/systemd/system/multi-user.target.wants"
ln -sv "/usr/lib/systemd/system/NetworkManager.service" "$airootfs/systemd/system/multi-user.target.wants"

mkdir -p "$airootfs/systemd/system/network-online.target.wants"
ln -sv "/usr/lib/systemd/system/NetworkManager-wait-online.service" "$airootfs/systemd/system/network-online.target.wants"

ln -sv "/usr/lib/systemd/system/NetworkManager-dispatcher.service" "$airootfs/systemd/system/dbus.org.freedesktop.dispatcher.service"

## Bluetooth
ln -sv "/usr/lib/systemd/system/bluetooth.service" "$airootfs/systemd/system/network-online.target.wants"

## Grahical Target
ln -s "/usr/lib/systemd/system/graphical.target" "$airootfs/systemd/system/default.target"

## SDDM
ln -s "/usr/lib/systemd/system/sddm.service" "$airootfs/systemd/system/display-manager.service"

# SDDM conf
mkdir -p "$airootfs/sddm.conf.d"
sed -n '1,35p' /usr/lib/sddm/sddm.conf.d/default.conf > $airootfs/sddm.conf
sed -n '38,137p' /usr/lib/sddm/sddm.conf.d/default.conf > $airootfs/sddm.conf.d/kde_settings.conf

## Desktop Enviroment
sed -i 's/Session=/Session=plasma.desktop/' $airootfs/sddm.conf

## Display Server
sed -i 's/DisplayServer=x11/DisplayServer=wayland/' $airootfs/sddm.conf

## User
user=localuser
sed -i 's/User=/User='$user'/' $airootfs/sddm.conf

# Hostname
echo NimbOS > $airootfs/hostname

# Create User
if grep -q "$user" $airootfs/passwd 2> /dev/null; then
    echo -e "\nUser Found..."
else
    sed -i '1 a\'"$user:x:1000:1000::/home/$user:/usr/bin/bash" $airootfs/passwd
    echo -e "\nUser Not Found..."
fi

## Password
hash_pd=$(openssl passwd -6 passwd)

if grep -q "$user" $airootfs/shadow 2> /dev/null; then
    echo -e "\nPassword Exists"
else
    sed -i '1 a\'"$user:$hash_pd:14871::::::" $airootfs/shadow
    echo -e "\nPassword Modified"
fi

# Groups
touch $airootfs/group
echo -e "root:x:0:root\nadm:x:4:$user\nwheel:x:10:$user\nuucp:x:14:$user\n$user:x:1000:$user" > $airootfs/group

# gshadow
touch $airootfs/gshadow
echo -e "root:!*::root\n$user:!*::" > $airootfs/gshadow

# Grub Config
grubcfg=(grub/grub.cfg)
sed -i 's/default=archlinux/default=NimbOS/' $grubcfg
sed -i 's/menuentry "Arch/menuentry "NimbOS/' $grubcfg

if ! grep -q 'archisosearchuuid=%ARCHISO_UUID% cow_spacesize=10G copytoram=n' $grubcfg 2> /dev/null; then
    sed -i 's/archisosearchuuid=%ARCHISO_UUID%/archisosearchuuid=%ARCHISO_UUID% cow_spacesize=10G copytoram=n/' $grubcfg
fi

# EFI Loader
efiloader=(efiboot/loader)
sed -i 's/Arch/NimbOS/' $efiloader/entries/01-archiso-x86_64-linux-lts.conf
sed -i 's/Arch/NimbOS/' $efiloader/entries/02-archiso-x86_64-speech-linux-lts.conf
