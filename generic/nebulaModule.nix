{ config, lib, hostName, ...}:

let
  cfg = config.myModules.nebula;
  enabledInterfaces = lib.filterAttrs (n: v: v.enable) cfg.interfaces;
  enabledInterfacesList = lib.mapAttrsToList (name: value: {inherit name value;}) enabledInterfaces;
  portList = builtins.genList (i: 51821+i) (builtins.length enabledInterfacesList);
  enabledInterfacesWithPortList = lib.zipListsWith (iface: port: {name = iface.name; value = iface.value // {port = port;};}) enabledInterfacesList portList;
  enabledInterfacesWithPort = builtins.listToAttrs enabledInterfacesWithPortList;
  serviceGroup = "nebulaUsers"; #group that all nebula users are in so that they all can access the same ca.crt file
in 
{
  #sops config for nebula key
  imports = [ 
    ./sops.nix
  ];

  options.myModules.nebula = {
    interfaces = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          enable = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Enable or disable this interface";
          };
          secretHostName = lib.mkOption {
            type = lib.types.str;
            default = hostName;
            description = ''
              flake hostName of the device that decrypts and creates the interface.
            '';
          };
          installHostName = lib.mkOption {
            type = lib.types.str;
            default = hostName;
            description = ''
              flake hostName of the device on which the interface should run. Determines which crt is being used. If not using an container-like setup then this will be the same as hostName.
            '';
            example = "testing-cont";
          };
          isLighthouse = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = ''
              Whether this host is a nebula lighthouse. This also configures this host as a relay automatically.
            '';
          };
          serverFirewallRules = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = ''
              Whether to apply certain server specific firewall rules like all icmp traffic and ssh port.
            '';
          };
        };
      });
    };
  };

  config = lib.mkIf (enabledInterfaces != {}) {
    users.groups."${serviceGroup}" = {};

    sops.secrets = lib.mkMerge ([{
      "nebula/ca.crt" = {
        group = serviceGroup;
        mode = "0440";
        sopsFile = ../secrets/nebula.yaml;
      };}] ++ (lib.mapAttrsToList (netName: netCfg: let
      serviceUser = config.systemd.services."nebula@${netName}".serviceConfig.User;
    in {
      "nebula/${netCfg.installHostName}.key" = {
        owner = serviceUser;
        sopsFile = ../secrets/${netCfg.secretHostName}/nebula.yaml;
      };
      "nebula/${netCfg.installHostName}.crt" = {
        owner = serviceUser;
        sopsFile = ../secrets/${netCfg.secretHostName}/nebula.yaml;
      };
    }) enabledInterfaces));

    systemd.services = lib.mkMerge (lib.mapAttrsToList (netName: netCfg: {
      "nebula@${netName}".serviceConfig.Group = lib.mkForce serviceGroup;
    }) enabledInterfaces);

    services.nebula.networks = lib.mkMerge (lib.mapAttrsToList (netName: netCfg: {
      "${netName}" = rec {
        enable = true;
        ca = config.sops.secrets."nebula/ca.crt".path;
        key = config.sops.secrets."nebula/${netCfg.installHostName}.key".path;
        cert = config.sops.secrets."nebula/${netCfg.installHostName}.crt".path;
        listen.port = netCfg.port;
        lighthouses = lib.mkIf (!netCfg.isLighthouse) [ "48.42.0.1" "48.42.0.5" ];
        isLighthouse = netCfg.isLighthouse;
        isRelay = netCfg.isLighthouse;
        relays = lib.mkIf (!netCfg.isLighthouse) lighthouses;
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
          inbound = lib.mkIf netCfg.serverFirewallRules [
            {
              port = "any";
              proto = "icmp";
              host = "any";
            }
            {
              port = 22;
              proto = "tcp";
              group = "admin";
            }
          ];
        };
      };
    }) enabledInterfacesWithPort);
  };
}
