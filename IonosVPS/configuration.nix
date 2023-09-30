{ ... }: 

{
  imports = [
    ./proxy.nix
  ];

  boot.loader.grub.device = "/dev/vda";
  boot.initrd.availableKernelModules = [ "ata_piix" "uhci_hcd" "xen_blkfront" "vmw_pvscsi" ];
  boot.initrd.kernelModules = [ "nvme" ];
  fileSystems."/" = { device = "/dev/vda1"; fsType = "ext4"; };

  networking.domain = "";

  boot.tmp.cleanOnBoot = true;
  zramSwap.enable = true;

  #nebula firewall
  services.nebula.networks."serverNetwork".firewall.inbound = [
    {
      port = "22";
      proto = "tcp";
      group = "admin";
    }
  ];
}
