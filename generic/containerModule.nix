{
  lib,
  config,
  pkgs,
  inputs,
  hostName,
  ...
}:

let
  cfg = config.myModules.container;
  enabledContainers = lib.filterAttrs (n: v: v.enable) cfg.containers;
  getPrefix = (
    v:
    if v.mullvadRouting then
      "10.42.44"
    else
      (if (v.nebulaGateway != null) then "10.42.43" else "10.42.42")
  );
  getIP = (v: "${getPrefix v}.${builtins.toString v.hostID}");
  dnsRecords = lib.mergeAttrsList (
    lib.mapAttrsToList (n: v: {
      "${getIP v}" = v.associatedDomains;
    }) enabledContainers
  );
  containersEnabled = enabledContainers != { };
  nebulaContainersEnabled = (lib.filterAttrs (_: v: !v.mullvadRouting) enabledContainers) != { };
  nebulaGatewayContainersEnabled =
    (lib.filterAttrs (_: v: v.nebulaGateway != null) enabledContainers) != { };
  mullvadContainersEnabled = (lib.filterAttrs (_: v: v.mullvadRouting) enabledContainers) != { };
  nebulaContainerIPNetId = "10.28.129";
in
{
  imports = [
    ./nebulaModule.nix
  ];

  options.myModules.container = {
    externalNetworkInterface = lib.mkOption {
      type = lib.types.str;
      description = "The external network interface that is used for the default route of this machine (where it gets internet connection over)";
    };
    mullvadPrivateKeyFile = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Path to the file containing the wireguard private key for the mullvad config";
    };
    associatedHostDomains = lib.mkOption {
      type = lib.types.listOf lib.types.singleLineStr;
      default = [ ];
      description = "A list of domains associated with the host machine. All containers will have DNS records changed such that they will directly point to the internal ip address of the host machine";
    };
    containers = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            enable = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Whether this container should be enabled";
            };
            mullvadRouting = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "Whether the containers internet traffic should be routed (and forced) through mullvad";
            };
            after = lib.mkOption {
              type = lib.types.listOf lib.types.singleLineStr;
              default = [ ];
              description = "List of container names that are required for running this container";
            };
            enableSops = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "Whether sops-nix should be enabled inside the container";
            };
            hostID = lib.mkOption {
              type = lib.types.ints.u8;
              description = "Host ID of local and nebula IP address (equivalent to what vmID was for Proxmox VMs before)";
            };
            nebulaGateway = lib.mkOption {
              type = lib.types.nullOr lib.types.singleLineStr;
              default = null;
              description = "If this container should only have access to its nebula interface (aside from loopback) and route everything through the nebula network then set this to the nebula IP of the nebula device that should be the gateway (i.e. exit node)";
            };
            openTCPPorts = lib.mkOption {
              type = lib.types.listOf lib.types.port;
              default = [ ];
              description = "List of TCP ports that should be opened at container (for both NixOS firewall and nebula firewall for edge group)";
            };
            openUDPPorts = lib.mkOption {
              type = lib.types.listOf lib.types.port;
              default = [ ];
              description = "List of UDP ports that should be opened at container (for both NixOS firewall and nebula firewall for edge group)";
            };
            forwardPorts = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "Whether to forward opened udp and tcp ports to the local external interface using dnat";
            };
            associatedDomains = lib.mkOption {
              type = lib.types.listOf lib.types.singleLineStr;
              default = [ ];
              description = "A list of domains associated with this container. Other containers will have DNS records changed such that they will directly point to this containers internal ip address";
            };
            permittedUnfreePackages = lib.mkOption {
              type = lib.types.listOf lib.types.singleLineStr;
              default = [ ];
              description = "List of unfree package names that should be allowed inside this container";
            };
            additionalBindMounts = lib.mkOption {
              type = lib.types.attrs;
              default = { };
              description = "Bind mounts in addition to the one to /persist/backMeUp and /persist/sops-nix";
            };
            additionalContainerConfig = lib.mkOption {
              type = lib.types.attrs;
              default = { };
              description = "Additional configuration that will be put into the NixOS module under containers.<name>, e.g. to configure extra capabilities";
            };
            additionalSpecialArgs = lib.mkOption {
              type = lib.types.attrs;
              default = { };
              description = "A set of special arguments to be passed to the containers NixOS modules";
            };
            config = lib.mkOption {
              type = lib.types.path;
              description = "Path to config file. Note that some things like stateVersion and DNS fixes are already being configured by this module for all containers.";
            };
          };
        }
      );
    };
  };

  config = lib.mkIf containersEnabled {
    assertions = [
      {
        assertion = mullvadContainersEnabled && cfg.mullvadPrivateKeyFile != null;
        message = "If you want to use mullvad containers, then you have to set the 'mullvadPrivateKeyFile' option as well";
      }
      {
        assertion =
          !(lib.any (v: v.mullvadRouting && v.nebulaGateway != null) (builtins.attrValues enabledContainers));
        message = "You cannot set 'nebulaGateway' on a container with mullvad routing";
      }
      {
        assertion =
          !(lib.any (v: v.forwardPorts && v.mullvadRouting) (builtins.attrValues enabledContainers));
        message = "You cannot enable 'forwardPorts' on a container with mullvad routing";
      }
      {
        assertion =
          !(lib.any (v: v.forwardPorts && v.nebulaGateway != null) (builtins.attrValues enabledContainers));
        message = "You cannot enable 'forwardPorts' on a container with 'nebulaGateway' defined";
      }
    ];

    #setup nebula connection for every container
    myModules.nebula = builtins.mapAttrs (n: v: {
      secretHostName = hostName;
      installHostName = n;
      ipMap = config.myModules.nebula."serverNetwork".ipMap;
      lighthouseMap = config.myModules.nebula."serverNetwork".lighthouseMap;
    }) enabledContainers;
    services.nebula.networks = (
      builtins.mapAttrs (n: v: {
        settings.tun.unsafe_routes = lib.mkIf (v.nebulaGateway != null) [
          {
            route = "0.0.0.0/0";
            via = v.nebulaGateway;
            install = false;
          }
        ];
        firewall.inbound =
          (builtins.concatLists (
            builtins.map (port: [
              {
                port = port;
                proto = "tcp";
                group = "edge";
              }
              {
                #allow admins to bypass reverse proxy for debugging/maintenance purposes
                port = port;
                proto = "tcp";
                group = "admin";
              }
            ]) v.openTCPPorts
          ))
          ++ (builtins.concatLists (
            builtins.map (port: [
              {
                port = port;
                proto = "udp";
                group = "edge";
              }
              {
                port = port;
                proto = "udp";
                group = "admin";
              }
            ]) v.openUDPPorts
          ));
      }) enabledContainers
    );

    #networking stuff that all containers share. systemd service templates
    #every container gets their own network namespace, nebula interface and optionally veth pair
    #taken from https://uint.one/posts/all-internet-over-wireguard-using-systemd-networkd-on-nixos/ and adapted for my use case with nebula
    boot.kernel.sysctl."net.ipv4.ip_forward" = lib.mkDefault 1;
    networking = {
      hosts = dnsRecords // {
        "127.0.0.1" = cfg.associatedHostDomains;
      };
      nftables = {
        enable = true;
        tables."custom_container_rules" = lib.mkIf mullvadContainersEnabled {
          family = "ip";
          content = ''
            chain forward {
              type filter hook forward priority filter; policy accept;

              # allow established traffic
              ct state established,related accept

              # allow br0 to go to external interface (no VPN)
              iifname "br0" oifname "${cfg.externalNetworkInterface}" accept

              # allow mullvad containers to the mullvad interface (VPN)
              iifname "br2" oifname "wg0-mullvad" accept
          ''
          + lib.optionalString nebulaContainersEnabled ''

            # nebula containers -> nebula gateway containers
            ip saddr 10.42.42.0/24 ip daddr 10.42.43.0/24 accept

            # nebula containers <- nebula gateway containers
            ip saddr 10.42.43.0/24 ip daddr 10.42.42.0/24 accept

            # nebula containers -> mullvad containers
            ip saddr 10.42.42.0/24 ip daddr 10.42.44.0/24 accept

            # nebula containers <- mullvad containers
            ip saddr 10.42.44.0/24 ip daddr 10.42.42.0/24 accept

            # nebula gateway containers -> mullvad containers
            ip saddr 10.42.43.0/24 ip daddr 10.42.44.0/24 accept

            # nebula gateway containers <- mullvad containers
            ip saddr 10.42.44.0/24 ip daddr 10.42.43.0/24 accept
          ''
          + ''
              # drop anything nebula gateway containers (kill switch)
              iifname "br1" drop

              # drop anything else from mullvad containers (kill switch)
              iifname "br2" drop
            }

            chain postrouting {
              type nat hook postrouting priority srcnat; policy accept;

              # NAT mullvad container subnet when leaving via mullvad
              ip saddr 10.42.44.0/24 oifname "wg0-mullvad" masquerade
            }
          '';
        };
      };
      firewall = {
        checkReversePath = "loose";
        allowedTCPPorts = (
          builtins.concatLists (
            lib.mapAttrsToList (n: v: if v.forwardPorts then v.openTCPPorts else [ ]) enabledContainers
          )
        );
        allowedUDPPorts = (
          builtins.concatLists (
            lib.mapAttrsToList (n: v: if v.forwardPorts then v.openUDPPorts else [ ]) enabledContainers
          )
        );
      };
      nat = {
        enable = true;
        internalInterfaces = [ "br0" ];
        externalInterface = cfg.externalNetworkInterface;
        enableIPv6 = false;
        forwardPorts = (
          builtins.concatLists (
            lib.mapAttrsToList (
              n: v:
              if v.forwardPorts then
                (
                  (builtins.map (tcp_port: {
                    destination = "10.42.42.${builtins.toString v.hostID}:${builtins.toString tcp_port}";
                    proto = "tcp";
                    sourcePort = tcp_port;
                  }) v.openTCPPorts)
                  ++ (builtins.map (udp_port: {
                    destination = "10.42.42.${builtins.toString v.hostID}:${builtins.toString udp_port}";
                    proto = "udp";
                    sourcePort = udp_port;
                  }) v.openUDPPorts)
                )
              else
                [ ]
            ) enabledContainers
          )
        );
      };
    };
    systemd = lib.mkMerge (
      #configure bridge for nebula containers
      (lib.optional nebulaContainersEnabled {
        network = {
          netdevs."20-br0".netdevConfig = {
            Kind = "bridge";
            Name = "br0";
          };
          networks."20-br0" = {
            name = "br0";
            DHCP = "no";
            addresses = [
              {
                Address = "10.42.42.1/24";
              }
            ];
          };
        };
      })
      ++ (lib.optional nebulaGatewayContainersEnabled {
        network = {
          netdevs."20-br1".netdevConfig = {
            Kind = "bridge";
            Name = "br1";
          };
          networks."20-br1" = {
            name = "br1";
            DHCP = "no";
            addresses = [
              {
                Address = "10.42.43.1/24";
              }
            ];
          };
        };
      })
      #configure bridge for mullvad containers
      ++ (lib.optional mullvadContainersEnabled {
        network = {
          netdevs = {
            "20-br2".netdevConfig = {
              Kind = "bridge";
              Name = "br2";
            };
            "30-wg0_mullvad" = {
              netdevConfig = {
                Kind = "wireguard";
                Name = "wg0-mullvad";
              };
              wireguardConfig = {
                ListenPort = 51820;
                PrivateKeyFile = cfg.mullvadPrivateKeyFile;
              };
              wireguardPeers = [
                {
                  PublicKey = "vVQKs2TeTbdAvl3sH16UWLSESncXAj0oBaNuFIUkLVk=";
                  AllowedIPs = [
                    "::/0"
                    "0.0.0.0/0"
                  ];
                  RouteTable = 1000;
                  Endpoint = "185.209.196.73:51820";
                }
              ];
            };
          };
          networks = {
            "20-br2" = {
              name = "br2";
              DHCP = "no";
              addresses = [
                {
                  Address = "10.42.44.1/24";
                }
              ];
            };
            "30-wg0_mullvad" = {
              matchConfig.Name = "wg0-mullvad";
              address = [
                "10.72.66.107/32"
                "fc00:bbbb:bbbb:bb01::9:426a/128"
              ];
              dns = [
                "10.64.0.1"
              ];
              routingPolicyRules = [
                {
                  Family = "both";
                  IncomingInterface = "br2";
                  Table = 1000;
                  Priority = 10;
                }
                {
                  To = "10.42.42.0/24";
                  Priority = 5;
                }
                {
                  To = "10.42.43.0/24";
                  Priority = 5;
                }
              ];
            };
          };
        };
      })
      #configure some overwrites for all containers
      ++ (lib.mapAttrsToList (n: v: {
        tmpfiles.settings."10-containerMountDirs" =
          lib.optionalAttrs v.enableSops {
            "/persist/sops-nix/${n}"."d" = {
              user = "root";
              group = "root";
              mode = "0755";
            };
          }
          // lib.mkMerge (
            lib.mapAttrsToList (n: v: {
              "${v.hostPath}"."d" = {
                user = "root";
                group = "root";
                mode = "0755";
              };
            }) v.additionalBindMounts
          );
        #setting container startup order
        services."container@${n}".after = builtins.map (v: "container@${v}.service") v.after;
      }) enabledContainers)
      #configure custom systemd services for nebula containers
      ++ (lib.mapAttrsToList (
        n: v:
        let
          shortenedN = builtins.substring 0 11 n;
          nebulaMoveRequired = (v.nebulaGateway != null) || v.mullvadRouting;
        in
        {
          services = {

            "netns@${n}" = {
              description = "${n} containers veth network namespace";
              serviceConfig = with pkgs; {
                Type = "oneshot";
                RemainAfterExit = true;
                ExecStart = "${iproute2}/bin/ip netns add ${shortenedN}";
                ExecStop = "${iproute2}/bin/ip netns del ${shortenedN}";
              };
            };
            "lo@${n}" = {
              description = "loopback in ${n} containers network namespace";

              bindsTo = [ "netns@${n}.service" ];
              after = [ "netns@${n}.service" ];

              serviceConfig = {
                Type = "oneshot";
                RemainAfterExit = true;
                ExecStart =
                  let
                    start =
                      with pkgs;
                      writeShellScript "lo-up" ''
                        set -e

                        ${iproute2}/bin/ip -n $1 addr add 127.0.0.1/8 dev lo
                        ${iproute2}/bin/ip -n $1 link set lo up
                      '';
                  in
                  "${start} ${shortenedN}";
                ExecStopPost = with pkgs; "${iproute2}/bin/ip -n ${shortenedN} link del lo";
              };
            };
            "veth@${n}" = {
              description = "virtual ethernet network interface between the main and ${n} containers network namespaces";

              bindsTo = [
                "netns@${n}.service"
                "network-online.target"
              ];
              after = [
                "netns@${n}.service"
                "network-online.target"
              ];

              serviceConfig = {
                Type = "oneshot";
                RemainAfterExit = true;
                ExecStart =
                  let
                    start =
                      with pkgs;
                      writeShellScript "veth-${n}-up" ''
                        set -e
                        ${iproute2}/bin/ip link add ve-${shortenedN} type veth peer name eth-${shortenedN}
                        ${iproute2}/bin/ip link set eth-${shortenedN} netns ${shortenedN}
                        ${iproute2}/bin/ip -n ${shortenedN} link set dev eth-${shortenedN} name eth-lan
                        ${iproute2}/bin/ip -n ${shortenedN} addr add 10.42.42.${builtins.toString v.hostID}/24 dev eth-lan
                        ${iproute2}/bin/ip -n ${shortenedN} link set eth-lan up
                        ${iproute2}/bin/ip link set dev ve-${shortenedN} master br0
                        ${iproute2}/bin/ip link set ve-${shortenedN} up
                        ${iproute2}/bin/ip -n ${shortenedN} route add default via 10.42.42.1
                      '';
                  in
                  "${start}";
                ExecStopPost =
                  let
                    stop =
                      with pkgs;
                      writeShellScript "veth-down" ''
                        ${iproute2}/bin/ip -n $1 link del eth-lan
                        ${iproute2}/bin/ip link del ve-$1
                      '';
                  in
                  "${stop} ${shortenedN}";
              };
            };
            "nebulaVeth@${n}" =
              let
                nebulaSystemdService = config.systemd.services."nebula@${n}";
              in
              {
                description = "nebula network interface in ${n} containers network namespace (same one where veth is in)";

                bindsTo = [
                  "netns@${n}.service"
                  "veth@${n}.service"
                ];
                wants = [
                  "network-online.target"
                  "nss-lookup.target"
                ];
                after = [
                  "netns@${n}.service"
                  "veth@${n}.service"
                  "network-online.target"
                  "nss-lookup.target"
                ];

                unitConfig.StartLimitIntervalSec = 0;

                serviceConfig =
                  with pkgs;
                  lib.mkMerge [
                    nebulaSystemdService.serviceConfig
                    {
                      ExecStart = lib.mkForce "${iproute2}/bin/ip netns exec ${shortenedN} ${nebulaSystemdService.serviceConfig.ExecStart}";
                      CapabilityBoundingSet = lib.mkForce [
                        "CAP_SYS_ADMIN"
                        "CAP_NET_ADMIN"
                      ];
                      AmbientCapabilities = lib.mkForce [
                        "CAP_SYS_ADMIN"
                        "CAP_NET_ADMIN"
                      ];
                      RestrictNamespaces = lib.mkForce false;
                      RestrictSUIDSGID = lib.mkForce false;
                    }
                  ];
              };

            #overwriting default systemd services
            "container@${n}" =
              let
                serviceList =
                  if nebulaMoveRequired then
                    [
                      "lo@neb-${n}.service"
                      "moveNebNS@${n}.service"
                      "veth@neb-${n}.service"
                    ]
                  else
                    [
                      "lo@${n}.service"
                      "nebulaVeth@${n}.service"
                    ];
              in
              {
                requires = serviceList;
                after = serviceList;
              };
            "nebula@${n}".enable = lib.mkForce false; # we have our own systemd service
          }
          // lib.optionalAttrs nebulaMoveRequired {
            "netns@neb-${n}" = {
              description = "${n} containers nebula-only network namespace";
              serviceConfig = with pkgs; {
                Type = "oneshot";
                RemainAfterExit = true;
                ExecStart = "${iproute2}/bin/ip netns add neb-${shortenedN}";
                ExecStop = "${iproute2}/bin/ip netns del neb-${shortenedN}";
              };
            };
            "lo@neb-${n}" = {
              description = "loopback in ${n} containers nebula-only network namespace";

              bindsTo = [ "netns@neb-${n}.service" ];
              after = [ "netns@neb-${n}.service" ];

              serviceConfig = {
                Type = "oneshot";
                RemainAfterExit = true;
                ExecStart =
                  let
                    start =
                      with pkgs;
                      writeShellScript "lo-up" ''
                        set -e

                        ${iproute2}/bin/ip -n $1 addr add 127.0.0.1/8 dev lo
                        ${iproute2}/bin/ip -n $1 link set lo up
                      '';
                  in
                  "${start} neb-${shortenedN}";
                ExecStopPost = with pkgs; "${iproute2}/bin/ip -n neb-${shortenedN} link del lo";
              };
            };
            "moveNebNS@${n}" = {
              description = "Move nebula interface of ${n} container into its own nebula-only network namespace";

              bindsTo = [
                "netns@neb-${n}.service"
                "nebulaVeth@${n}.service"
              ];
              after = [
                "netns@neb-${n}.service"
                "nebulaVeth@${n}.service"
              ];

              unitConfig = {
                StartLimitBurst = 10;
                StartLimitInterval = 11;
              };

              serviceConfig =
                with pkgs;
                let
                  nebulaInterfaceName = builtins.substring 0 15 "neb-${n}";
                in
                {
                  Type = "oneshot";
                  RemainAfterExit = true;
                  ExecStart =
                    let
                      start =
                        with pkgs;
                        writeShellScript "moveNebNS-${n}" (
                          ''
                            set -e
                            ${iproute2}/bin/ip -n ${shortenedN} link set ${nebulaInterfaceName} netns neb-${shortenedN}
                            ${iproute2}/bin/ip -n neb-${shortenedN} addr add ${nebulaContainerIPNetId}.${builtins.toString v.hostID} dev ${nebulaInterfaceName}
                            ${iproute2}/bin/ip -n neb-${shortenedN} link set ${nebulaInterfaceName} up
                            ${iproute2}/bin/ip -n neb-${shortenedN} route add ${
                              config.myModules.nebula."serverNetwork".subnet
                            } dev ${nebulaInterfaceName}
                          ''
                          + lib.optionalString (v.nebulaGateway != null) ''
                            ${iproute2}/bin/ip -n neb-${shortenedN} route add default via ${v.nebulaGateway}
                          ''
                        );
                    in
                    "${start}";
                  ExecStop = "${iproute2}/bin/ip link set ${nebulaInterfaceName} ${shortenedN}";
                  Restart = "on-failure";
                  RestartSec = 1;
                };
            };
            "veth@neb-${n}" = {
              description = "virtual ethernet network interface between the main and ${n} containers nebula-only network namespaces";

              bindsTo = [
                "netns@neb-${n}.service"
                "network-online.target"
              ];
              after = [
                "netns@neb-${n}.service"
                "moveNebNS@${n}.service"
                "network-online.target"
              ];

              serviceConfig = {
                Type = "oneshot";
                RemainAfterExit = true;
                ExecStart =
                  let
                    start =
                      with pkgs;
                      writeShellScript "veth-neb-${n}-up" (
                        ''
                          set -e
                          ${iproute2}/bin/ip link add ven-${shortenedN} type veth peer name etn-${shortenedN}
                          ${iproute2}/bin/ip link set etn-${shortenedN} netns neb-${shortenedN}
                          ${iproute2}/bin/ip -n neb-${shortenedN} link set dev etn-${shortenedN} name eth-lan
                          ${iproute2}/bin/ip -n neb-${shortenedN} addr add ${getIP v}/24 dev eth-lan
                          ${iproute2}/bin/ip -n neb-${shortenedN} link set eth-lan up
                          ${iproute2}/bin/ip link set dev ven-${shortenedN} master ${
                            if v.mullvadRouting then "br2" else "br1"
                          }
                          ${iproute2}/bin/ip link set ven-${shortenedN} up
                        ''
                        + lib.optionalString (v.nebulaGateway != null) ''
                          ${iproute2}/bin/ip -n neb-${shortenedN} route add 10.42.42.0/24 dev eth-lan via ${getPrefix v}.1
                          ${iproute2}/bin/ip -n neb-${shortenedN} route add 10.42.44.0/24 dev eth-lan via ${getPrefix v}.1
                        ''
                        + lib.optionalString v.mullvadRouting ''
                          ${iproute2}/bin/ip -n neb-${shortenedN} route add default via 10.42.44.1
                        ''
                      );
                  in
                  "${start}";
                ExecStopPost =
                  let
                    stop =
                      with pkgs;
                      writeShellScript "veth-down" ''
                        ${iproute2}/bin/ip -n $1 link del eth-lan
                        ${iproute2}/bin/ip link del ven-$1
                      '';
                  in
                  "${stop} ${shortenedN}";
              };
            };
          };
          #if the system uses systemd networkd, then mark our manually created veth interface as unmanaged so that networkd doesn't touch it
          network.networks."20-${n}-unmanaged" = lib.mkIf config.systemd.network.enable {
            matchConfig.Name = "ve-${shortenedN}";
            linkConfig.Unmanaged = true;
          };
        }
      ) enabledContainers)
    );

    containers = builtins.mapAttrs (
      n: v:
      let
        shortenedN = builtins.substring 0 11 n;
        nebulaMoveRequired = (v.nebulaGateway != null) || v.mullvadRouting;
      in
      {
        autoStart = true;
        ephemeral = true;

        #even changing age key for one machine will trigger a restart of containers.
        #we want to restart them explicitly only when needed (or on reboot)!
        restartIfChanged = false;

        networkNamespace =
          if nebulaMoveRequired then "/run/netns/neb-${shortenedN}" else "/run/netns/${shortenedN}";
        bindMounts =
          lib.optionalAttrs v.enableSops {
            "/persist/sops-nix" = {
              hostPath = "/persist/sops-nix/${n}";
              isReadOnly = false;
            };
          }
          // v.additionalBindMounts;

        specialArgs = {
          hostName = n;
          inputs = inputs;
        }
        // v.additionalSpecialArgs;

        config =
          { hostName, ... }:
          {
            imports = [
              v.config
              ./promtail.nix # to get systemd-journal out of container into loki
            ]
            ++ lib.lists.optional v.enableSops ./sops.nix;
            myModules.promtail.host = "${getPrefix v}.1";
            nixpkgs.config.allowUnfreePredicate =
              pkg: builtins.elem (lib.getName pkg) v.permittedUnfreePackages;
            networking = {
              hostName = hostName;
              useHostResolvConf = lib.mkForce false;
              firewall = {
                allowedTCPPorts = v.openTCPPorts;
                allowedUDPPorts = v.openUDPPorts;
              };
              hosts =
                (lib.filterAttrs (ip: _: ip != (getIP v)) dnsRecords)
                // (
                  let
                    hostIP = "${getPrefix v}.1";
                  in
                  {
                    "${hostIP}" = cfg.associatedHostDomains;
                    "127.0.0.1" = v.associatedDomains;
                  }
                );
            };
            services.resolved.enable = true;
            system.stateVersion = config.system.stateVersion; # stateVersion of container should be the same as the one of the host
          };
      }
      // v.additionalContainerConfig
    ) enabledContainers;
  };
}
