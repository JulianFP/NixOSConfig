{ lib, vmID, inputs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      inputs.disko.nixosModules.disko
      ./commonHM.nix
      ./server.nix
    ];

  boot.initrd.availableKernelModules = [ "ata_piix" "uhci_hcd" "virtio_pci" "virtio_scsi" "sd_mod" "sr_mod" ];
  boot.initrd.kernelModules = [ "dm-snapshot" ];
  boot.loader.grub = {
    efiSupport = true;
    efiInstallAsRemovable = true;
  };

  #filesystem setup
  disko.devices = import ./proxmoxVM-disk-config.nix {
    inherit lib;
  };
  fileSystems = {
    "/" = {
      device = "/dev/disk/by-partlabel/disk-_dev_sda-nixos";
      fsType = "btrfs";
      options = [ "subvol=root" ];
    };
    "/home" = {
      device = "/dev/disk/by-partlabel/disk-_dev_sda-nixos";
      fsType = "btrfs";
      options = [ "subvol=home" ];
    };
    "/nix" = {
      device = "/dev/disk/by-partlabel/disk-_dev_sda-nixos";
      fsType = "btrfs";
      options = [ "subvol=nix" ];
    };
    "/swap" = {
      device = "/dev/disk/by-partlabel/disk-_dev_sda-nixos";
      fsType = "btrfs";
      options = [ "subvol=swap" ];
    };
    "/boot" = {
      device = "/dev/disk/by-partlabel/disk-_dev_sda-ESP";
      fsType = "vfat";
    };
  };

#networking config (systemd.network preferred over networking)
  networking = {
    useDHCP = false;
    enableIPv6 = false;
  };
  systemd.network =  {
    enable = true;
    networks."10-serverLAN" = {
      name = "ens*";
      DHCP = "no";
      networkConfig.IPv6AcceptRA = false;
      address = [
        "192.168.3.${vmID}/24"
      ];
      gateway = [
        "192.168.3.1"
      ];
      dns = [
        "1.1.1.1"
        "8.8.8.8"
      ];
    };
  };

  #automatic garbage collect and nix store optimisation is done in server.nix
  #automatic upgrade. Pulls newest commits from github daily. Relies on my updating the flake inputs (I want that to be manual and tracked by git)
  system.autoUpgrade = {
    enable = true;
    flake = "github:JulianFP/NixOSConfig";
    dates = "04:00";
    randomizedDelaySec = "30min";
    allowReboot = true;
    rebootWindow = {
      lower = "04:00";
      upper = "05:00";
    };
  };
}
