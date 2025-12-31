{ config, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../generic/proxyConfig.nix
    ../generic/dnat.nix
  ];

  networking.domain = "";

  zramSwap.enable = true; # enable zram (instead of swap)

  #nebula lighthouse + unsafe_routes settings
  myModules.nebula."serverNetwork".isLighthouse = true;
  services.nebula.networks."serverNetwork".settings.tun.unsafe_routes = [
    {
      route = "192.168.3.0/24";
      via = config.myModules.nebula."serverNetwork".ipMap.mainserver;
    }
    {
      route = "10.42.42.0/24";
      via = config.myModules.nebula."serverNetwork".ipMap.mainserver;
    }
  ];

  #reverse proxy config
  myModules.proxy = {
    enable = true;
    isEdge = true;
  };

  #dnat setup
  myModules.dnat = {
    enable = true;
    externalInterface = "ens6";
    portForwards = [
      #Valheim
      {
        sourcePort = 2456;
        proto = "udp";
        destinationNebulaHost = "ValheimMarvin";
      }
      {
        sourcePort = 2457;
        proto = "udp";
        destinationNebulaHost = "ValheimMarvin";
      }
      {
        sourcePort = 2458;
        proto = "udp";
        destinationNebulaHost = "ValheimBrueder";
      }
      {
        sourcePort = 2459;
        proto = "udp";
        destinationNebulaHost = "ValheimBrueder";
      }
    ];
  };

  #use options of generic/wireguard.nix module
  myModules.servers.wireguard = {
    enable = true;
    externalInterface = "ens6";
    publicKeys = [
      "byifao8fmvsS7Dc/k8NnYwqbuFzSPtiRf/ZcKyK0hgw=" # JuliansFramework
      "12I+6LyvdoagWTctUOg40YoitODSFDrnFF2gfo2ILTU=" # Marias Laptop
    ];
  };
}
