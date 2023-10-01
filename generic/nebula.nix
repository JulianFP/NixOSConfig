{ config, hostName, ...}:

# requires you to manually update .sops.yaml file if sops key got generated

let
  netName = "serverNetwork";
in 
{
  #sops config for nebula key
  imports = [ 
    ./sops.nix
  ];
  sops.secrets."nebula/${hostName}.key" = {
    mode = "0440";
    owner = "nebula-${netName}";
    group = "nebula-${netName}";
    sopsFile = ../secrets/${hostName}/nebula.yaml;
  };
  sops.secrets."nebula/${hostName}.crt" = {
    mode = "0440";
    owner = "nebula-${netName}";
    group = "nebula-${netName}";
    sopsFile = ../secrets/${hostName}/nebula.yaml;
  };
  sops.secrets."nebula/ca.crt" = {
    mode = "0440";
    owner = "nebula-${netName}";
    group = "nebula-${netName}";
    sopsFile = ../secrets/nebula.yaml;
  };
  systemd.services."nebula@${netName}" = {
    serviceConfig.SupplementaryGroups = [ config.users.groups.keys.name ];
  };

  # nebula config
  services.nebula.networks."${netName}" = {
    enable = true;
    ca = config.sops.secrets."nebula/ca.crt".path;
    key = config.sops.secrets."nebula/${hostName}.key".path;
    cert = config.sops.secrets."nebula/${hostName}.crt".path;
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
