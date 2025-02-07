{ ... }:

{
  networking = {
    nftables.enable = true;
    firewall.allowedTCPPorts = [ 
      #23 
    ];
    nat = {
      enable = true;
      internalInterfaces = [ "neb-serverNetwo" ];
      externalInterface = "ens6";
      forwardPorts = [
      /*
        {
          sourcePort = 23;
          proto = "tcp";
          destination = "config.myModules.nebula."serverNetwork".ipMap.Nextcloud-Testing:23";
        }
      */
      ];
    };
  };

  services.nebula.networks."serverNetwork".firewall.inbound = [{
    port = "any";
    proto = "any";
    group = "server";
  }];
}
