{ config, pkgs, lib, modulesPath, ... }:

#select latest zfs compatible kernel
let
  zfsCompatibleKernelPackages = lib.filterAttrs (
    name: kernelPackages:
    (builtins.match "linux_[0-9]+_[0-9]+" name) != null
    && (builtins.tryEval kernelPackages).success
    && (!kernelPackages.${config.boot.zfs.package.kernelModuleAttribute}.meta.broken)
  ) pkgs.linuxKernel.packages;
  latestKernelPackage = lib.last (
    lib.sort (a: b: (lib.versionOlder a.kernel.version b.kernel.version)) (
      builtins.attrValues zfsCompatibleKernelPackages
    )
  );
in {
  imports = [
    (modulesPath + "/installer/cd-dvd/installation-cd-graphical-calamares-plasma6.nix")
  ];

  boot.initrd.kernelModules = [
    "dm-snapshot" # when you are using snapshots
    "dm-raid" # e.g. when you are configuring raid1 via: `lvconvert -m1 /dev/pool/home`
    "dm-cache-default" # when using volumes set up with lvmcache
    "dm-mirror" # for pvmove
  ];

  environment.systemPackages = with pkgs; [ 
    keyutils
    multipath-tools #for kpartx for opening disks in lvm volumes
  ];

  boot = {
    kernelPackages = latestKernelPackage;
    supportedFilesystems = {
      bcachefs = true;
      btrfs = true;
      zfs = true;
    };
  };

  services.lvm.boot.thin.enable = true; #to mount pve volumes
}
