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
          destination = "48.42.1.150:23";
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
