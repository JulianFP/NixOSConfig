{ config, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../generic/proxyConfig.nix
    ./dnat.nix
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
}
