{ lib, ... }: 

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

  #nebula firewall + lighthouse settings
  services.nebula.networks."serverNetwork" = {
    lighthouses = lib.mkForce [ ];
    isLighthouse = true;
    firewall.inbound = [
      {
        port = "22";
        proto = "tcp";
        group = "admin";
      }
      {
        port = "22";
        proto = "tcp";
        group = "server";
      }
    ];
    settings.tun.unsafe_routes = [{
      route = "192.168.3.0/24";
      via = "48.42.0.2";
    }];
  };

  #use options of generic/wireguard.nix module 
  myModules.servers.wireguard = {
    enable = true;
    externalInterface = "ens6";
    publicKeys = [ 
      "byifao8fmvsS7Dc/k8NnYwqbuFzSPtiRf/ZcKyK0hgw=" #JuliansFramework
      "12I+6LyvdoagWTctUOg40YoitODSFDrnFF2gfo2ILTU=" #Marias Laptop
    ];
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?
}
