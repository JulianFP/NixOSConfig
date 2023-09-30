{ ... }:

{
  boot.initrd.availableKernelModules = [ "ata_piix" "uhci_hcd" "virtio_pci" "virtio_scsi" "sd_mod" "sr_mod" ];
  boot.initrd.kernelModules = [ "dm-snapshot" ];

  networking = {
    enableIPv6 = false;
    nameservers = [
      "192.168.3.1"
      "1.1.1.1"
    ];
    interfaces = {
      ens18 = {
        ipv4.addresses = [{
          address = "192.168.3.200";
          prefixLength = 24;
        }];
        useDHCP = false;
      };
    };
    defaultGateway = {
      address = "192.168.3.1";
      interface = "ens18";
    };
  };
}
