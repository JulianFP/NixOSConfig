{ ... }:

{
  boot.initrd.availableKernelModules = [ "ata_piix" "uhci_hcd" "virtio_pci" "virtio_scsi" "sd_mod" "sr_mod" ];
  boot.initrd.kernelModules = [ "dm-snapshot" ];

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
        "192.168.3.200/24"
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

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?
}
