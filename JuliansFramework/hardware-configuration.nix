# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, modulesPath, ... }:

{
  imports =
    [ (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "thunderbolt" "nvme" "usbhid" "usb_storage" "sd_mod" ];
  # set kernel modules for luks
  boot.initrd.kernelModules = [ "vfat" "nls_cp437" "nls_iso8859-1" "usbhid" ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/bfb60ba4-5f30-4af6-b754-4e720ebbde8e";
      fsType = "btrfs";
      options = [ "subvol=root" ];
    };

# setup luks device with yubikey as second factor (refer to https://wiki.nixos.org/wiki/Yubikey_based_Full_Disk_Encryption_(FDE)_on_NixOS)
  boot.initrd.luks = {
    yubikeySupport = true;
    devices."nixosLuks" = {
      device = "/dev/disk/by-uuid/a1540879-2cdd-495a-be71-8b6c31f93915";
      preLVM = true;
      yubikey = {
        slot = 1;
        twoFactor = true;
        storage.device = "/dev/disk/by-uuid/8E8F-15B7";
      };
    };
  };

  fileSystems."/home" =
    { device = "/dev/disk/by-uuid/bfb60ba4-5f30-4af6-b754-4e720ebbde8e";
      fsType = "btrfs";
      options = [ "subvol=home" ];
    };

  fileSystems."/swap" =
    { device = "/dev/disk/by-uuid/bfb60ba4-5f30-4af6-b754-4e720ebbde8e";
      fsType = "btrfs";
      options = [ "subvol=swap" ];
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/8E8F-15B7";
      fsType = "vfat";
    };

  swapDevices = [ {
    device = "/swap/swapfile";
    size = 8*1024;
  } ];

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.enp0s13f0u1u3.useDHCP = lib.mkDefault true;
  # networking.interfaces.wlp166s0.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
