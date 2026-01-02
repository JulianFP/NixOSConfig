{ lib, config, ... }:

let
  cfg = config.myModules.dnat;
  nebulaIpMap = config.myModules.nebula."serverNetwork".ipMap;
in
{
  options.myModules.dnat = {
    enable = lib.mkEnableOption ("Dnat");
    externalInterface = lib.mkOption {
      type = lib.types.singleLineStr;
      description = "Interface for incoming traffic to should get forwarded";
    };
    portForwards = lib.mkOption {
      type = lib.types.listOf (
        lib.types.submodule (
          { config, ... }:
          {
            options = {
              proto = lib.mkOption {
                type = lib.types.enum [
                  "tcp"
                  "udp"
                ];
                default = "tcp";
                description = "The protocol to forward";
              };
              sourcePort = lib.mkOption {
                type = lib.types.port;
                description = "Source port";
              };
              destinationPort = lib.mkOption {
                type = lib.types.port;
                description = "Destination port";
                default = config.sourcePort;
              };
              destinationNebulaHost = lib.mkOption {
                type = lib.types.enum (builtins.attrNames nebulaIpMap);
                description = "Nebula host name where traffic should go to";
              };
            };
          }
        )
      );
      description = "Ports to be forwarded";
    };
  };

  config = lib.mkIf cfg.enable {
    networking = {
      nftables = {
        enable = true;
        flushRuleset = true;
        tables."nixos-nat" = {
          family = "ip";
          content = ''
            chain post {
              masquerade
            }
          '';
        };
      };
      firewall = {
        allowedTCPPorts = builtins.map (x: x.sourcePort) (
          builtins.filter (x: x.proto == "tcp") cfg.portForwards
        );
        allowedUDPPorts = builtins.map (x: x.sourcePort) (
          builtins.filter (x: x.proto == "udp") cfg.portForwards
        );
      };
      nat = {
        enable = true;
        internalInterfaces = [ "neb-serverNetwo" ];
        externalInterface = cfg.externalInterface;
        forwardPorts = builtins.map (
          x:
          let
            destinationIp = nebulaIpMap."${x.destinationNebulaHost}";
          in
          {
            sourcePort = x.sourcePort;
            proto = x.proto;
            destination = "${destinationIp}:${builtins.toString x.destinationPort}";
          }
        ) cfg.portForwards;
      };
    };

    services.nebula.networks."serverNetwork".firewall.inbound = [
      {
        port = "any";
        proto = "any";
        local_cidr = "any";
        group = "server";
      }
    ];
  };
}
