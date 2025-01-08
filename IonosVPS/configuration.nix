{ ... }: 

{
  imports = [
    #./dnat.nix #for dnat config (currently not in use, conflicts with wireguard setup)
  ];

  boot.loader.grub.device = "/dev/vda";
  boot.initrd.availableKernelModules = [ "ata_piix" "uhci_hcd" "xen_blkfront" "vmw_pvscsi" ];
  boot.initrd.kernelModules = [ "nvme" ];
  fileSystems."/" = { device = "/dev/vda1"; fsType = "ext4"; };

  networking.domain = "";

  #zramSwap.enable = true; #enable zram (instead of swap)

  #nebula lighthouse + unsafe_routes settings
  myModules.nebula.interfaces."serverNetwork".isLighthouse = true;
  services.nebula.networks."serverNetwork".settings.tun.unsafe_routes = [
    {
      route = "192.168.3.0/24";
      via = "48.42.0.2";
    }
    {
      route = "10.42.42.0/24";
      via = "48.42.0.2";
    }
  ];

  #use options of generic/wireguard.nix module 
  myModules.servers.wireguard = {
    enable = true;
    externalInterface = "ens6";
    publicKeys = [ 
      "byifao8fmvsS7Dc/k8NnYwqbuFzSPtiRf/ZcKyK0hgw=" #JuliansFramework
      "12I+6LyvdoagWTctUOg40YoitODSFDrnFF2gfo2ILTU=" #Marias Laptop
    ];
  };
}
