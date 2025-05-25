{ lib, config, ... }:

{
  imports = [
    ../generic/disk-config-btrfs-impermanence.nix
  ];
  
  boot.initrd.availableKernelModules = [ "pata_sis" "ohci_pci" "ehci_pci" "sata_sis" "usb_storage" "sd_mod" "sr_mod" ];

  myModules.disko-btrfs-impermanence = {
    enable = true;
    uefiOnlySystem = false;
  };

  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
