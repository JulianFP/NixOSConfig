{
  config,
  pkgs,
  lib,
  ...
}:

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
in
{
  boot = {
    initrd.kernelModules = [
      "dm-snapshot" # when you are using snapshots
      "dm-raid" # e.g. when you are configuring raid1 via: `lvconvert -m1 /dev/pool/home`
      "dm-cache-default" # when using volumes set up with lvmcache
      "dm-mirror" # for pvmove
    ];
    kernelPackages = latestKernelPackage;
    supportedFilesystems = {
      bcachefs = true;
      btrfs = true;
      zfs = true;
    };
  };

  environment = {
    systemPackages = with pkgs; [
      keyutils
      multipath-tools # for kpartx for opening disks in lvm volumes

      cryptsetup
      exfatprogs
      git
      firefox
      kdePackages.konversation
      keepassxc
      magic-wormhole
      rsync
      age
      (import ../generic/packages/shellScriptBin/vlan.nix { inherit pkgs; })

      #on-screen keyboard
      pkgs.maliit-framework
      pkgs.maliit-keyboard
    ];

    #save some space
    plasma6.excludePackages = [
      # Optional wallpapers that add 126 MiB to the graphical installer
      # closure. They will still need to be downloaded when installing a
      # Plasma system, though.
      pkgs.kdePackages.plasma-workspace-wallpapers
    ];
  };

  programs = {
    partition-manager.enable = true;

    # Avoid bundling an entire MariaDB installation on the ISO.
    kde-pim.enable = false;
  };

  services = {
    lvm.boot.thin.enable = true; # to mount pve volumes

    pipewire = {
      enable = true;
      pulse.enable = true;
    };

    displayManager = {
      sddm.enable = true;
      autoLogin = {
        enable = true;
        user = "nixos";
      };
    };
    desktopManager.plasma6.enable = true;

    # yubikey setup
    udev.packages = [ pkgs.yubikey-personalization ];
    pcscd.enable = true;
  };

  networking = {
    networkmanager.enable = true;
    hostId = "a81642f0";
  };

  powerManagement.enable = true;

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  # VM guest additions to improve host-guest interaction
  services.spice-vdagentd.enable = true;
  services.qemuGuest.enable = true;
  virtualisation.vmware.guest.enable = pkgs.stdenv.hostPlatform.isx86;
  # https://github.com/torvalds/linux/blob/00b827f0cffa50abb6773ad4c34f4cd909dae1c8/drivers/hv/Kconfig#L7-L8
  virtualisation.hypervGuest.enable =
    pkgs.stdenv.hostPlatform.isx86 || pkgs.stdenv.hostPlatform.isAarch64;
  services.xe-guest-utilities.enable = pkgs.stdenv.hostPlatform.isx86;
  # The VirtualBox guest additions rely on an out-of-tree kernel module
  # which lags behind kernel releases, potentially causing broken builds.
  virtualisation.virtualbox.guest.enable = false;

  # Whitelist wheel users to do anything
  # This is useful for things like pkexec
  #
  # WARNING: this is dangerous for systems
  # outside the installation-cd and shouldn't
  # be used anywhere else.
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (subject.isInGroup("wheel")) {
        return polkit.Result.YES;
      }
    });
  '';

  #placeholder since I build this device as ISO anyway mostly
  #I want nix flake check to pass though
  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/installISO";
      fsType = "bcachefs";
    };
    "/boot" = {
      label = "INSTALL-UEFI";
      fsType = "vfat";
    };
  };
}
