{ ... }:

{
  networking = {
    nftables = {
      enable = true;
      ruleset = ''
          table ip nat {
            chain PREROUTING {
              type nat hook prerouting priority dstnat; policy accept;
              iifname "ens6" tcp dport 25565 dnat to 48.42.1.110:25565
              iifname "ens6" udp dport 25565 dnat to 48.42.1.110:25565
            }
          }
      '';
    };
    firewall = {
      enable = true;
      allowedTCPPorts = [ 23 ];
    };
    nat = {
      enable = true;
      internalInterfaces = [ "ens6" ];
      externalInterface = "nebula.serverNe";
      forwardPorts = [
        {
          sourcePort = 25565;
          proto = "tcp";
          destination = "48.42.1.110:25565";
        }
        {
          sourcePort = 25565;
          proto = "udp";
          destination = "48.42.1.110:25565";
        }
      ];
    };
  };
}
