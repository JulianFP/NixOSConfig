{ lib, config, ... }:

{
  imports = [
    ../generic/disk-config-btrfs-impermanence.nix
  ];

  boot.initrd.availableKernelModules = [
    "ehci_pci"
    "ahci"
    "usb_storage"
    "sd_mod"
    "sdhci_pci"
  ];
  boot.kernelModules = [ "kvm-intel" ];

  myModules.disko-btrfs-impermanence = {
    enable = true;
    uefiOnlySystem = true;
  };

  #since this is a laptop
  services.logind.settings.Login.HandleLidSwitch = "ignore";

  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
