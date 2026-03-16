{
  config,
  lib,
  hostName,
  ...
}:

let
  enabledNetworks = lib.filterAttrs (n: v: v.enable) config.myModules.nebula;
  enabledInterfacesList = lib.mapAttrsToList (name: value: { inherit name value; }) enabledNetworks;
  portList = builtins.genList (i: 51821 + i) (builtins.length enabledInterfacesList);
  enabledInterfacesWithPortList = lib.zipListsWith (iface: port: {
    name = iface.name;
    value = iface.value // {
      port = port;
    };
  }) enabledInterfacesList portList;
  enabledInterfacesWithPort = builtins.listToAttrs enabledInterfacesWithPortList;
  serviceGroup = "nebulaUsers"; # group that all nebula users are in so that they all can access the same ca.crt file
  getNetName = (netName: builtins.substring 0 15 "neb-${netName}");
  unsafeRoutesEnabled = lib.any (v: v.unsafeRoutes != { }) (builtins.attrValues enabledNetworks);
in
{
  #sops config for nebula key
  imports = [
    ./sops.nix
  ];

  options.myModules.nebula = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        options = {
          enable = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Enable or disable this network";
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
          enableIPv6 = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = ''
              Whether to listen on IPv6 interfaces and add IPv6 addresses to static maps (in addition to IPv4)
            '';
          };
          subnet = lib.mkOption {
            description = "The Subnet of the Nebula network in CIDR notation";
            type = lib.types.str;
          };
          ipMap = lib.mkOption {
            description = "Each entry in this attribute set is a hostName - nebula ip address pair for easy lookup. See ./nebula.nix for how it is populated";
            type = lib.types.attrsOf lib.types.str;
          };
          lighthouseMap = lib.mkOption {
            description = "Map Hostnames in ipMap to non-nebula IP-addresses and mark these hostnames as lighthouses";
            type = lib.types.attrsOf (lib.types.listOf lib.types.str);
          };
          unsafeRoutes = lib.mkOption {
            type = lib.types.attrsOf (lib.types.listOf lib.types.singleLineStr);
            default = { };
            description = "An attribute set mapping interface names to lists of subnets";
          };
        };
      }
    );
  };

  config = lib.mkIf (enabledNetworks != { }) {
    users.groups."${serviceGroup}" = { };

    sops.secrets = lib.mkMerge (
      [
        {
          "nebula/ca.crt" = {
            group = serviceGroup;
            mode = "0440";
            sopsFile = ../secrets/nebula.yaml;
          };
        }
      ]
      ++ (lib.mapAttrsToList (
        netName: netCfg:
        let
          serviceUser = config.systemd.services."nebula@${netName}".serviceConfig.User;
        in
        {
          "nebula/${netCfg.installHostName}.key" = {
            owner = serviceUser;
            sopsFile = ../secrets/${netCfg.secretHostName}/nebula.yaml;
          };
          "nebula/${netCfg.installHostName}.crt" = {
            owner = serviceUser;
            sopsFile = ../secrets/${netCfg.secretHostName}/nebula.yaml;
          };
        }
      ) enabledNetworks)
    );

    systemd.services = lib.mkMerge (
      lib.mapAttrsToList (netName: netCfg: {
        "nebula@${netName}".serviceConfig.Group = lib.mkForce serviceGroup;
      }) enabledNetworks
    );

    #exclude nebula interface from networkmanager
    networking.networkmanager.unmanaged = lib.mapAttrsToList (
      netName: _: getNetName netName
    ) enabledInterfacesWithPort;

    services.nebula.networks = lib.mkMerge (
      lib.mapAttrsToList (
        netName: netCfg:
        let
          allUnsafeSubnets = builtins.concatLists (builtins.attrValues netCfg.unsafeRoutes);
        in
        {
          "${netName}" = rec {
            enable = true;
            ca = config.sops.secrets."nebula/ca.crt".path;
            key = config.sops.secrets."nebula/${netCfg.installHostName}.key".path;
            cert = config.sops.secrets."nebula/${netCfg.installHostName}.crt".path;
            tun.device = "neb-${netName}"; # shorter interface names
            listen = {
              host = if netCfg.enableIPv6 then "[::]" else "0.0.0.0";
              port = netCfg.port;
            };
            lighthouses = lib.mkIf (!netCfg.isLighthouse) (
              lib.attrVals (builtins.attrNames netCfg.lighthouseMap) netCfg.ipMap
            );
            isLighthouse = netCfg.isLighthouse;
            isRelay = netCfg.isLighthouse;
            relays = lib.mkIf (!netCfg.isLighthouse) lighthouses;
            staticHostMap = lib.mapAttrs' (
              name: value: lib.nameValuePair (builtins.getAttr name netCfg.ipMap) value
            ) netCfg.lighthouseMap;
            settings = {
              cipher = "aes";
              punchy = {
                punch = true;
                respond = true;
              };
              preferred_ranges = allUnsafeSubnets;
            };
            firewall = {
              outbound = [
                {
                  host = "any";
                  port = "any";
                  proto = "any";
                }
              ];
              inbound =
                (builtins.map (subnet: {
                  port = "any";
                  proto = "any";
                  local_cidr = subnet;
                  group = "admin";
                }) allUnsafeSubnets)
                ++ lib.optionals netCfg.serverFirewallRules [
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
        }
      ) enabledInterfacesWithPort
    );

    boot.kernel.sysctl."net.ipv4.ip_forward" = lib.mkIf unsafeRoutesEnabled 1;
    networking.nftables = lib.mkIf unsafeRoutesEnabled {
      enable = true;
      tables = lib.mergeAttrsList (
        lib.mapAttrsToList (
          netName: netCfg:
          lib.mergeAttrsList (
            lib.mapAttrsToList (interface: subnets: {
              "nebula_${netName}_unsafeRoutes_${interface}" = {
                family = "ip";
                content = ''
                  chain postrouting {
                    type nat hook postrouting priority srcnat; policy accept;
                    ip saddr ${
                      config.myModules.nebula."serverNetwork".subnet
                    } ip daddr { ${lib.concatStringsSep ", " subnets} } counter masquerade
                  }

                  chain forward {
                    type filter hook forward priority filter; policy accept;
                    ct state related,established counter accept
                    iifname ${getNetName netName} oifname ${interface} ip saddr ${
                      config.myModules.nebula."serverNetwork".subnet
                    } ip daddr ${lib.concatStringsSep ", " subnets} counter accept
                  }
                '';
              };
            }) netCfg.unsafeRoutes
          )
        ) enabledNetworks
      );
    };
  };
}
