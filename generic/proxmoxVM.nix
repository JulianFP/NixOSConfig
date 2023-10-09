{ lib, vmID, inputs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      inputs.disko.nixosModules.disko
      ./server.nix
    ];

  boot.initrd.availableKernelModules = [ "ata_piix" "uhci_hcd" "virtio_pci" "virtio_scsi" "sd_mod" "sr_mod" ];
  boot.initrd.kernelModules = [ "dm-snapshot" ];
  boot.loader.grub = {
    efiSupport = true;
    efiInstallAsRemovable = true;
  };

  disko.devices = import ./proxmoxVM-disk-config.nix {
    inherit lib;
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
}
