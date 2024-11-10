## About
This is the NixOS config for my Framework 12th Gen Laptop (home-manager config included).

## My custom boot process
I boot of a normal FAT32 UEFI partition. I use lanzaboote (modified systemd-boot) as a bootloader to be able to enable (and enforce) secureboot. In initrd stage I use systemd to support my heavily modified process: First, a luks encrypted ext4 partition will be unlocked using the clevis framework. I set it up in a way that allows me to unlock that partition automatically using a combination of tpm2 and fido2. If and only if both the tpm2 chip and the fido2 device provide their part of the security key, clevis will be able to unlock its key and use it to decrypt the luks partition. This encrypted key is stored in the luks partitions header (this way it cannot affect the PCR stores values). If this doesn't work I have to type in the password manually and will now that something is up. I set up tpm2 to use measured boot: If any of the configured PCR stores have a different hash-value than at the time I set this up, the tpm2 will not release the secret. This way I will notice if somebody tempered with my firmware or BIOS even before unlocking my disk.
The ext4 partition is then being mounted. It contains only two key-files: One for the main bcachefs partition, and one for the swap partition. The system will use these to unlock these two partitions, and then unmounts and locks the ext4 partition again.
After that it proceeds to check whether it can resume from hibernation from the swap partition. If yes, then it will do that (the mount points during hibernation are stored in the swap partition, fstab entries are not being used). If no, then it will run my impermanence script: The bcachefs partition gets temporarily mounted and the root partition will be snapshoted into a read-only subvolume in /old-roots. After that the script will cleanup old snapshots, delete and recreate the root partition and unmount again. And then finally, the normal fstab mount and switch_root occurs. I also modified the switch_root part to switch into the root subvolume instead, see below for more information about that.

## bcachefs + impermanence
Where do I even start. Well, I wanted to use bcachefs and a NixOS impermanence setup on my laptop. I had good experiences with impermanence on my servers and wanted it on my laptop too, except with bcachefs instead of btrfs because why not and its new and hot and native encryption and performance and stuff. On my servers I implemented impermanence with btrfs subvolumes since that way I can still keep old root volumes around just in case and it also doesn't eat up my memory like a tmpfs would. So I tried the same thing with bcachefs. I started by formatting my drive with bcachefs, and then creating subvolumes for root, nix, persist and home as usual. The only thing left was to mount the root subvolume under /, and then the others under that. And that is where I realized, that bcachefs doesn't allow mounting subvolumes! Bcachefs subvolumes are basically just fancy directories, one can only mount the filesystem as a whole. Keep in mind that at this point I had already evacuated and reformated my SSD and was working from a booted LIVE iso, so I was in for the ride! First I searched for a way to rollback snapshots (which bcachefs supports) to an older version. That way I could have made an empty snapshot of the filesystem and just rolled back to it during boot (similarly how impermanence is often done on zfs). But guess what: bcachefs [doesn't support rollbacks yet either](https://www.reddit.com/r/bcachefs/comments/18xd4gs/comment/kg4iktw). Also one cannot move subvolumes without also moving all their child subvolumes. This basically means that there is no way I can boot from the root of the filesystem and then empty it without touching my persist, home and nix subvolumes. So I started looking for workarounds:
**Workaround 1**: Bind mounts! On Linux, you cannot just mount filesystems, but also directories of filesystems onto other directories. I tried a very cursed thing: Using the command `mount --bind /mnt/root /mnt -o x-gvfs-hide` I tried to mount the root subvolume onto the filesystem-root (I used the x-gvfs-hide mount option so that these mounts do not show up as a drive in my file manager). Surprisingley, bcachefs actually let me do this and it seemed to work....at first. Then I noticed that suddenly files that previously were in my persist subvolume are not visible anymore after this bind mount (files outside of subvolumes however were). Furthermore, if I created files in these subvolumes and then umounted the bind-mount the old files would reapear but the new files would disappear (only to reappear when repeating that bind-mount). So if you ever need to hide files from analysis tools (similarly as how you used to be able to on ntfs), then this is it, but unfortunetely because of this bug it doesn't solve my problem.
**Workaround 2**: If you read the [man docs for the mount system call](https://www.reddit.com/r/bcachefs/comments/18xd4gs/comment/kg4iktw) you will find the `X-mount.subdir` mount option. This basically allows us to mount a subdir of a filesystem instead of its root! Imagine how stoked I was to find out about this [in this reddit thread](https://www.reddit.com/r/bcachefs/comments/1b3uv59) after trying all that bind-mount bullshit, only to find out its flaw in the very same reddit thread: Apparentely there is a bug in bcachefs or in util-linux or somewhere that prevents this from working ([here is the Github issue for it](https://github.com/util-linux/util-linux/issues/2834)). When typing `mount /dev/<device> /mnt -o X-mount.subdir=root` it would run without error but wouldn't actually mount the damn filesystem. Apparentely it works if the `LIBMOUNT_FORCE_MOUNT2` environmental variable is set, but setting it inside initrd seems to be a little bit more tricky than one might think and it felt too much like a hack to rely my boot process on it. So on to Workaround 3! 
**Workaround 3**: This goes a bit deep into the Linux boot process, I recommend these reads to understand this: [rootfs vs. initrd vs. initramfs and switch_root system call](https://www.marcusfolkesson.se/blog/changing-the-root-of-your-linux-filesystem/) as well as [its execution using systemd in initramfs (yes that is a thing)](https://www.man7.org/linux/man-pages/man7/bootup.7.html). So the idea is to basically overwrite systemd's initrd-switch-root.service that is part of the initrd image so the we can give it our own adjusted switch_root command that does not switch to /sysroot (where the bcachefs filesystem would be mounted in initrd) but instead to /sysroot/root. Nice, right? Just wouldn't have thought that I would learn about some weird mount options and about intrigate details of the Linux boot process by just wanting to format my drive in bcachefs.....

## Todo
- [x] coherent nixified theming across the following programs (moved from nix-colors to stylix):
    - [x] Alacritty
    - [x] GTK
    - [x] Qt5
    - [x] Qt6
    - [x] all aspects of KDE applications from plasma-integration (KColorScheme: [how platform integrations work](https://nicolasfella.de/posts/how-platform-integration-works/). Waiting for [this pull request](https://github.com/trialuser02/qt6ct/pull/43) to get merged and reach nixpkgs. Some KDE programs currently have broken theming because of that, e.g.: kde's plasma 6 polkit agent (plasma 5 version works fine), plasma system monitor, plasma system settings. Standard Qt5/Qt6 applications (like dolphin, partition manager, filelight, wireshark, prismlauncher, ...) work fine though. EDIT: Used on overlay for now to apply that PR. See [this NUR repo for that](https://github.com/ilya-fedin/nur-repository).
    - [x] waybar
    - [x] mako
    - [x] rofi
    - [x] Hyprland (accent colors)
    - [x] neovim 
    - [x] mangohud
    - [x] wallpaper
- [x] complete neovim config using nixvim for full development environment/IDE (including bash script for creating C++ cmake environment and launching compiled program)
- [x] waybar config with custom mako module that works through RT signal communication
- [x] Hyprland config with some custom bash scripts for clamshell mode, lock and suspend, etc.
- [x] bash script for gpu switching
- [x] Add VPNs to networking (nebula, wireguard, ipsec) (done mostly manually in networkmanager)
- [x] Mangohud config
- [x] lf config
- [x] Additional applications and set default applications
- [x] yubikey fully working including for gpg and ssh
- [x] laptop power tuning
- [x] direnv enabled
- [x] easy monitor switching when connecting to random external monitors (e.g. for presentation) with Hyprland (python script for this)
- [x] Firefox & Thunderbird config
- [ ] bluefilter mode for hyprland?
- [ ] (automatic) timezone switcher for when traveling?

## new Install guide for bcachefs and impermanence
- `fdisk /dev/nvme0n1`, create partition table with efi system +1G, linux filesystem -24G, linux swap up to largest sector (don't forget to set partition types as well)
- `mkfs.vfat -F 32 -n UEFI /dev/nvme0n1p1`
- pick one of the outputs of the following command as password for the KeyPartition: `pwgen -cnysB 16`
- `cryptsetup luksFormat /dev/nvme0n1p2 --label=EncryptedKeyPartition`
- `cryptsetup open /dev/disk/by-label/EncryptedKeyPartition KeyPartition`
- `mkfs.ext4 -L KeyPartition /dev/mapper/KeyPartition`
- `mkdir /mnt1`
- `mount /dev/disk/by-label/KeyPartition /mnt2`
- `dd bs=512 count=8 if=/dev/random iflag=fullblock | install -m 0600 /dev/stdin /mnt2/JuliansEncryptedSwap.key`
- `pwgen -cnys 512 1 > /mnt2/JuliansNixOS.key`
- cat /mnt2/JuliansNixOS.key and use output as passphrase for the following: `bcachefs format --fs_label JuliansNixOS --encrypted --discard /dev/nvme0n1p3`
- `mount -t bcachefs -o noatime /dev/nvme0n1p3 /mnt && cd /mnt`
- `bcachefs subvolume create root && bcachefs subvolume create home && bcachefs subvolume create nix && bcachefs subvolume create persist`
- `mkdir /mnt/root/nix && mkdir /mnt/root/persist && mkdir /mnt/root/home && mkdir /mnt/root/boot`
- `mount -B /mnt/nix /mnt/root/nix && mount -B /mnt/persist /mnt/root/persist && mount -B /mnt/home /mnt/root/home`
- `mount -o umask=077 /dev/nvme0n1p1 /mnt/root/boot`
- `cryptsetup luksFormat /dev/nvme0n1p4 /mnt2/JuliansEncryptedSwap.key --label=JuliansEncryptedSwap`
- `cryptsetup open /dev/disk/by-label/JuliansEncryptedSwap swap --key-file /mnt2/JuliansEncryptedSwap.key`
- `mkswap --label JuliansSwap /dev/mapper/swap`
- use the deployment script with the sops option to modify the sops configuration to use your new age key (not modified&tested for localhost yet, read the script and use/modify the command in a sensible way manually for now!). Necessary before nixos-install and reboot because sops also unlocks the hash file that contains the user passwords!
- change boot to 1 (systemd-boot instead of lanzaboote) for JuliansFramework in flake.nix
- cd into directory where NixOSConfig is and execute (as root or with sudo) `nixos-install --root /mnt/root/ --flake .#JuliansFramework`)
- reboot and follow the after installation guides below (secureboot, clevis setup, ...)

## Old installation guide for btrfs (from NixOS ISO:)
- `sudo -i` login as root
- `loadkeys de-latin1` optional: switch to your preferred keyboard layout (important for entering passwords later on)
- Create two partitions on target disc: One EFI partition and one system partition (use fdisk or parted). The EFI partition has to be of type "EFI System"
- `nix-shell -p git` enter shell with git
- `git clone https://github.com/JulianFP/LaptopNixOSConfig` clone this repo
- `./LaptopNixOSConfig/installation-script.sh 1 /dev/nvme0n1p1 /dev/nvme0n1p2` run the installation script (change parameters accordingly!)
- `mv -f LaptopNixOSConfig/{.,}* /mnt/etc/nixos/` move local repo to /etc/nixos folder of target machine
- edit `/mnt/etc/nixos/JuliansFramework/hardware-configuration.nix` and change the uuids of all partitions to the values of your system (get them with the command `blkid`)
- In this file also change the `resume_offset` in `boot.kernelParams` to the output of this command: `sudo btrfs inspect-internal map-swapfile -r /swap/swapfile`
- edit `flake.nix` and in imports of JuliansFramework do the following: choose systemd-boot instead of lanzaboote. This will be reverted later, but is necessary for the initial installation
- `nixos-install --flake /mnt/etc/nixos/flake.nix#JuliansFramework` install system

## After initial installation (logged in as root)
- `nix run nixpkgs#sbctl create-keys` generate secure boot keys
- edit `flake.nix` and switch from systemd-boot to lanzaboote
- reboot and put laptop into Setup Mode (from firmware)
- `nix run nixpkgs#sbctl enroll-keys -- --microsoft` enroll keys to firmware
- `nixos-rebuild switch` to apply the config changes to did so far
- reboot again and enforce secure boot in firmware
- go into JuliansFramework directory of this git repo and execute `sudo clevis luks bind -d /dev/disk/by-label/EncryptedKeyPartition sss "$(<clevisConfig.json)"`
- nixos-rebuild switch and you may also want to push the config to github
- `fprintd-enroll -f left-index-finger julian` enroll fingerprints (fingerprint sensor). Repeat for other fingers or users (run as root and not with sudo, maybe run fprint-delete command first)
- restore home-folder data from backup (Documents, Pictures, Videos, some .local and .config stuff, ...)
- Start kwalletd5 in Terminal, log in into Nextcloud (setup synchronisation) and Nextcloud will prompt for the creation of a new kwallet (perform it)
- setup and log in various applications (like Signal, Discord, Lutris, Steam, etc.)

## Maintenance of Yubikey Luks partition: Resizing
Follow [this](https://wiki.nixos.org/wiki/Yubikey_based_Full_Disk_Encryption_(FDE)_on_NixOS#Maintenance) guide however make the following adjustments: Boot from a NixOS iso on a usb stick first, then mount the fat32 boot partition somewhere (e.g. /mnt). You need to make adjustments in the challenge and response command (change `/boot/crypt-storage/default` to `/mnt/crypt-storage/default` or to wherever you mounted the boot partition, change `-2` to `-1` if your yubikey uses a different slot for challenge response).

Proceed to resize the partition:
- resize the partition only (not filesystem): use `cfdisk` for that!
- open cryptsetup device: `cryptsetup open /dev/nvme0n1p2 nixos --key-file luks.key`
- resize luks to fit partition: `cryptsetup resize nixos --key-file luks.key`
- finally resize the btrfs partition inside the luks device: For this you need to mount it first (e.g. to /mnt), or reboot into it first. Then run `btrfs filesystem resize max /mount-point`
