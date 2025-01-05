{ lib, config, ... }:

{
  imports = [
    ../generic/disk-config-btrfs-impermanence.nix
  ];
  
  boot.initrd.availableKernelModules = [ "ahci" "xhci_pci" "ata_generic" "ehci_pci" "usbhid" "ums_realtek" "usb_storage" "sd_mod" "sr_mod" ];
  boot.initrd.kernelModules = [ "dm-snapshot" ];
  boot.kernelModules = [ "kvm-intel" ];

  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
