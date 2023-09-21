{ config, hostName, ...}:

# requires a working gnupg home at /root/.gnupg! Set it up with home-manager
#for servers you can use genericHomeManager/gnupg.nix

let
  netName = "serverNetwork";
in 
{
  #sops config for nebula key
  imports = [ 
    ./sops.nix
  ];
  sops.secrets."nebula/${hostName}" = {
    mode = "0440";
    owner = "nebula-${netName}";
    group = "nebula-${netName}";
  };
  systemd.services."nebula@${netName}" = {
    serviceConfig.SupplementaryGroups = [ config.users.groups.keys.name ];
  };

  # nebula config
  services.nebula.networks."${netName}" = {
    enable = true;
    ca = ../ca.crt;
    key = config.sops.secrets."nebula/${hostName}".path;
    cert = ../${hostName}/nebula.crt;
    listen.port = 51821;
    lighthouses = [ "48.42.0.1" ];
    staticHostMap = {
      "48.42.0.1" = [
        "82.165.49.241:51821"
      ];
    };
    settings = {
      cipher = "aes";
      punchy = {
        punch = true;
        respond = true;
      };
    };
    firewall = {
      outbound = [
        {
          host = "any";
          port = "any";
          proto = "any";
        }
      ];
      inbound = [
        {
          port = "any";
          proto = "icmp";
          host = "any";
        }
      ];
    };
  };
}
