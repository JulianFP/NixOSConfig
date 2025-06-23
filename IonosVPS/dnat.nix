{ config, ... }:

{
  networking = {
    nftables.enable = true;
    firewall.allowedUDPPorts = [
      2456
      2457
      2458
      2459
    ];
    nat = {
      enable = true;
      internalInterfaces = [ "neb-serverNetwo" ];
      externalInterface = "ens6";
      forwardPorts = [
        #Valheim
        {
          sourcePort = 2456;
          proto = "udp";
          destination = "${config.myModules.nebula."serverNetwork".ipMap.ValheimMarvin}:2456";
        }
        {
          sourcePort = 2457;
          proto = "udp";
          destination = "${config.myModules.nebula."serverNetwork".ipMap.ValheimMarvin}:2456";
        }
        {
          sourcePort = 2458;
          proto = "udp";
          destination = "${config.myModules.nebula."serverNetwork".ipMap.ValheimBrueder}:2456";
        }
        {
          sourcePort = 2459;
          proto = "udp";
          destination = "${config.myModules.nebula."serverNetwork".ipMap.ValheimBrueder}:2456";
        }
      ];
    };
  };

  services.nebula.networks."serverNetwork".firewall.inbound = [
    {
      port = "any";
      proto = "any";
      group = "server";
    }
  ];
}
