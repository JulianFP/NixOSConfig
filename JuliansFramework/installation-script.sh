#!/usr/bin/env bash
#nix-shell -p gcc yubikey-personalization openssl

rbtohex() {
	(od -An -vtx1 | tr -d ' \n')
}
hextorb() {
	(tr '[:lower:]' '[:upper:]' | sed -e 's/\([0-9A-F]\{2\}\)/\\\\\\x\1/gI' | xargs printf)
}

: '
This is a script that installs the system automatically for Yubikey based Full Disk Encryption
It basically automates the process described here: https://wiki.nixos.org/wiki/Yubikey_based_Full_Disk_Encryption_(FDE)_on_NixOS
Requirements:
- Booted into NixOS ISO on target system
- logged in as root
- internet access working
- yubikey with existing challenge response slot plugged in
- target disc already partitioned into EFI partition and system partition (these partitions will be formatted in this script!)
This script expects the following parameters:
1) SLOT number of yubikey to use
2) EFI partition
3) btrfs partition
e.g.: bash installation-script.sh 1 /dev/nvme0n1p1 /dev/nvme0n1p2
be ready to input the second factor password!
'
cc -O3 "-I$(nix-build "<nixpkgs>" --no-build-output -A openssl.dev)/include" "-L$(nix-build "<nixpkgs>" --no-build-output -A openssl.out)/lib" "$(nix eval --impure --extra-experimental-features nix-command --expr "(with import <nixpkgs> {}; pkgs.path)")/nixos/modules/system/boot/pbkdf2-sha512.c" -o ./pbkdf2-sha512 -lcrypto
SALT_LENGTH=16
salt="$(dd if=/dev/random bs=1 count=$SALT_LENGTH 2>/dev/null | rbtohex)"
echo " "
echo "Enter the password for the second factor of the LUKS partition now: "
read -s k_user -r
challenge="$(echo -n "$salt" | openssl dgst -binary -sha512 | rbtohex)"
response="$(ykchalresp -"$1" -x "$challenge" 2>/dev/null)"
KEY_LENGTH=512
ITERATIONS=1000000
k_luks="$(echo -n "$k_user" | ./pbkdf2-sha512 $((KEY_LENGTH / 8)) $ITERATIONS "$response" | rbtohex)"
EFI_MNT=/root/boot
mkdir "$EFI_MNT"
mkfs.vfat -F 32 -n UEFI "$2"
mount "$2" "$EFI_MNT"
STORAGE=/crypt-storage/default
mkdir -p "$(dirname $EFI_MNT$STORAGE)"
echo -ne "$salt\n$ITERATIONS" >$EFI_MNT$STORAGE
CIPHER=aes-xts-plain64
HASH=sha512
echo -n "$k_luks" | hextorb | cryptsetup luksFormat --cipher="$CIPHER" --key-size="$KEY_LENGTH" --hash="$HASH" --key-file=- "$3"
LUKSROOT=EncryptedNixOS
echo -n "$k_luks" | hextorb | cryptsetup luksOpen "$3" "$LUKSROOT" --key-file=-
mkfs.btrfs -L NixOS "/dev/mapper/$LUKSROOT"
mount "/dev/mapper/$LUKSROOT" /mnt
cd /mnt || exit 1
btrfs subvolume create root
btrfs subvolume create home
btrfs subvolume create swap
cd || exit 1
umount /mnt
mount "/dev/mapper/$LUKSROOT" /mnt -o subvol=root
mkdir /mnt/home
mkdir /mnt/boot
mkdir /mnt/swap
mkdir /mnt/etc
umount /root/boot
mount "$2" /mnt/boot
mount "/dev/mapper/$LUKSROOT" /mnt/home -o subvol=home
mount "/dev/mapper/$LUKSROOT" /mnt/swap -o subvol=swap
btrfs filesystem mkswapfile --size 8G /mnt/swap/swapfile
swapon /mnt/swap/swapfile
