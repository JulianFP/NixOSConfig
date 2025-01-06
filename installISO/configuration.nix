{ pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/cd-dvd/installation-cd-graphical-calamares-plasma6.nix")
  ];

boot.initrd.kernelModules = [
  "dm-snapshot" # when you are using snapshots
  "dm-raid" # e.g. when you are configuring raid1 via: `lvconvert -m1 /dev/pool/home`
  "dm-cache-default" # when using volumes set up with lvmcache
  "dm-mirror" # for pvmove
];
  #for latest bcachefs support in case I need to rescue the system
  environment.systemPackages = with pkgs; [ 
    keyutils
    multipath-tools #for kpartx for opening disks in lvm volumes
  ];
  boot = {
    supportedFilesystems = {
      bcachefs = true;
    };
  };

  services.lvm.boot.thin.enable = true; #to mount pve volumes
}
