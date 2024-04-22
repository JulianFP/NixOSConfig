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
    owner = config.systemd.services."nebula@${netName}".serviceConfig.User;
    sopsFile = ../secrets/${hostName}/nebula.yaml;
  };
  sops.secrets."nebula/${hostName}.crt" = {
    owner = config.systemd.services."nebula@${netName}".serviceConfig.User;
    sopsFile = ../secrets/${hostName}/nebula.yaml;
  };
  sops.secrets."nebula/ca.crt" = {
    owner = config.systemd.services."nebula@${netName}".serviceConfig.User;
    sopsFile = ../secrets/nebula.yaml;
  };

  # nebula config
  services.nebula.networks."${netName}" = {
    enable = true;
    ca = config.sops.secrets."nebula/ca.crt".path;
    key = config.sops.secrets."nebula/${hostName}.key".path;
    cert = config.sops.secrets."nebula/${hostName}.crt".path;
    listen.port = 51821;
    lighthouses = [ "48.42.0.1" "48.42.0.5" ];
    staticHostMap = {
      "48.42.0.1" = [
        "82.165.49.241:51821"
      ];
      "48.42.0.5" = [
        "85.215.33.173:51821"
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
