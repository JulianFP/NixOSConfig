{ config, lib, pkgs, inputs, ...}:

{
  # nebula config
  services.nebula.networks."serverNetwork" = {
    enable = true;
    ca = /root/.nebula/ca.crt;
    key = /root/.nebula/nixostesting.key;
    cert = /root/.nebula/nixostesting.crt;
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
        {
          port = "22";
          proto = "tcp";
          host = "any";
          group = "admin";
        }
        {
          port = "443";
          proto = "tcp";
          host = "any";
          group = "server";
        }
        {
          port = "80";
          proto = "tcp";
          host = "any";
          group = "server";
        }
      ];
    };
  };
}
