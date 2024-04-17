## About
This is the NixOS config for my Framework 12th Gen Laptop (home-manager config included).

## Todo
- [ ] coherent nixified theming across the following programs (using nix-colors):
    - [x] Alacritty
    - [x] GTK
    - [x] Qt5
    - [x] Qt6
    - [ ] all aspects of KDE applications from plasma-integration (KColorScheme: [how platform integrations work](https://nicolasfella.de/posts/how-platform-integration-works/). Waiting for [this pull request](https://github.com/trialuser02/qt6ct/pull/43) to get merged and reach nixpkgs. Some KDE programs currently have broken theming because of that, e.g.: kde's plasma 6 polkit agent (plasma 5 version works fine), plasma system monitor, plasma system settings. Standard Qt5/Qt6 applications (like dolphin, partition manager, filelight, wireshark, prismlauncher, ...) work fine though.
    - [x] waybar
    - [x] mako
    - [x] rofi
    - [x] Hyprland (accent colors)
    - [ ] neovim (vimThemeFromScheme function from contrib doesn't look good, have to write one myself)
    - [ ] mangohud
    - [ ] wallpaper?
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
- [ ] easy monitor switching when connecting to random external monitors (e.g. for presentation) with Hyprland -> custom bash script with rofi?
- [ ] Firefox/thunderbird config?

## Installation guide (from NixOS ISO:)
- `sudo -i` login as root
- `loadkeys de-latin1` optional: switch to your preferred keyboard layout (important for entering passwords later on)
- Create two partitions on target disc: One EFI partition and one system partition (use fdisk or parted). The EFI partition has to be of type "EFI System"
- `nix-shell -p git` enter shell with git
- `git clone https://github.com/JulianFP/LaptopNixOSConfig` clone this repo
- `./LaptopNixOSConfig/installation-script.sh 1 /dev/nvme0n1p1 /dev/nvme0n1p2` run the installation script (change parameters accordingly!)
- `mv -f LaptopNixOSConfig/{.,}* /mnt/etc/nixos/` move local repo to /etc/nixos folder of target machine
- edit `/mnt/etc/nixos/JuliansFramework/hardware-configuration.nix` and change the uuids of all partitions to the values of your system (get them with the command `blkid`)
- edit `flake.nix` and in imports of JuliansFramework do the following: choose systemd-boot instead of lanzaboote. This will be reverted later, but is necessary for the initial installation
- `nixos-install --flake /mnt/etc/nixos/flake.nix#JuliansFramework` install system

## After initial installation (logged in as root)
- `passwd julian` set password for users
- `nix run nixpkgs#sbctl create-keys` generate secure boot keys
- use the deployment script with the sops option to modify the sops configuration to use your new age key (not modified&tested for localhost yet, read the script and use/modify the command in a sensible way manually for now!)
- edit `flake.nix` and switch from systemd-boot to lanzaboote
- reboot and put laptop into Setup Mode (from firmware)
- `nix run nixpkgs#sbctl enroll-keys -- --microsoft` enroll keys to firmware
- `nixos-rebuild switch` to apply the config changes to did so far (you may also want to push them to github)
- reboot again and enforce secure boot in firmware
- `fprintd-enroll -f left-index-finger julian` enroll fingerprints (fingerprint sensor). Repeat for other fingers or users
- restore home-folder data from backup (Documents, Pictures, Videos, .mozilla and .thunderbird directories, ...)
- set thunderbird and firefox profile in about:config (in Thunderbird: Go to Help->Troubleshooting Information->Scroll down to about:profiles)
- Start kwalletd5 in Terminal, log in into Nextcloud (setup synchronisation) and Nextcloud will prompt for the creation of a new kwallet (perform it)
- setup and log in various applications (like Signal, Discord, Lutris, Steam, etc.)
